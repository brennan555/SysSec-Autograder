Import-Module VMware.VimAutomation.Core
$vSphereUser = "XXX"#Read-Host "vSphere Username"
$vSpherePass = "XXX"#Read-Host "vSphere Password" -AsSecureString
Connect-VIServer cdr-vcenter.cse.buffalo.edu -User $vSphereUser -Password $vSpherePass

Clear-Host
write-host("Grading Homework 4... This might take a while.")
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'
$VerbosePreference = 'SilentlyContinue'

function CheckState {
    param (
        [string]$SourceDevice,
        [string]$TestName,
        [string]$TestExpectedResult,
        [int]$AdditionalPoints,
        [string]$Passwd,
        [string]$Username,
        [string]$Script
    )
    $teamNumber = 1..24
    $teamNumber | Foreach-Object -ThrottleLimit 5 -Parallel { ##parallel is what allows the function to use multiple threads. Any parameters inside a thread must use $parameter.
        if ($_ -lt 10) { ## done because format for numbers <10 are 01, 02, etc.
            $number = "0$_"
        }
        else {
            $number = "$_"
        }
        Connect-VIServer -Server "cdr-vcenter.cse.buffalo.edu" -User "XXX" -Password "XXX" -Force
        $VM = Get-Folder "SysSec" | Get-Folder "Team_$number" | Get-VM $using:SourceDevice
        if ($VM.PowerState -eq "PoweredOff") { ## makes sure VMs are powered on before running scripts. NOTE: there is a bug where VMware tools will stop running if VM's go into hibernation. Fix in windwows power settings.
            Start-VM -VM $VM
            Write-Host "Powering on Team_$number $SourceDevice"
            Wait-Tools -VM $VM
        }
        $points = 0
        $ScriptResult = Invoke-VMScript -ScriptText $using:Script -GuestPassword $using:Passwd -GuestUser $using:Username -VM $VM -ToolsWaitSecs 60 ## will return output from script that is run.
        Write-output($ScriptResult.ScriptOutput)
        $ExpectedResult = $using:TestExpectedResult -f $_ ## formats parameters so that you a substitute team numbers for ip addresses. Ex: 10.42{0}.12
        Write-output("I am expected value $TestExpectedResult")
        if ($ScriptResult.ScriptOutput -match $ExpectedResult) {
            Write-Host("$using:TestName successful for Team $number $using:SourceDevice")
            $points += $using:AdditionalPoints
        }
        else {
            Write-Host("$using:TestName unsuccessful for Team $number $using:SourceDevice")
        }
        $TeamPoints += [PSCustomObject]@{
            Team   = "Team$number"
            Points = $points
        }
    } 
    return $TeamPoints
}



CheckState -SourceDevice "ADServer" -Script "Get-NetIPAddress | Where AddressFamily -eq 'IPv4' | Select-Object -ExpandProperty IPAddress | Select-Object -First 1" -Username "Administrator" -Passwd "Change.me!" -TestName "IP Address" -TestExpectedResult "10.42.{0}.98" -AdditionalPoints 2.5

