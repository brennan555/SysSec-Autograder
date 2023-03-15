##Clear-Host
$vSphereUser = "secdevlocal@vsphere.local"#Read-Host "vSphere Username"
$vSpherePass = "tallclub25"#Read-Host "vSphere Password" -AsSecureString
Connect-VIServer cdr-vcenter.cse.buffalo.edu -User $vSphereUser -Password $vSpherePass

Clear-Host
write-host("Grading Homework 4... This might take a while.")
$startTime = Get-Date
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'
$VerbosePreference = 'Continue'
function CheckState {
    param(
        $SourceDevice, ## device you are logging into
        $Script, ## script you want to run
        $Username, ## username for an account on $SourceDevice
        $Passwd, ## password for an account on $SourceDevice
        $TestName, ## name of what is being tested, for instance "Pinging 8.8.8.8 from Win10Client"
        $TestExpectedResult, ## the expected result of the script to determine successful system state
        $AdditionalPoints ## number of points you want test to be worth
    )

    $TeamPoints = @()
    for ($number = 1; $number -le 10; $number++) { ## change the upper bound number based on how many teams are being graded. 
        if ($number -lt 10) { ## done because format for numbers <10 are 01, 02, etc.
            $teamNumber = "0$number"
        }
        else {
            $teamNumber = $number
        }
        $VM = Get-Folder "SysSec" | Get-Folder "Team_$teamNumber" | Get-VM $SourceDevice
        if ($VM.PowerState -eq "PoweredOff") {## makes sure VMs are powered on before running scripts. NOTE: there is a bug where VMware tools will stop running if VM's go into hibernation. Fix in windwows power settings.
            Start-VM -VM $VM 
            Write-Host "Powering on Team_$teamNumber $SourceDevice"
            Wait-Tools -VM $VM
        }
        $points = 0

        $ScriptResult = Invoke-VMScript -ScriptText $Script -GuestPassword $Passwd -GuestUser $Username -VM $VM -ToolsWaitSecs 120 ## will return output from script that is run.
        Write-Host($ScriptResult)
        $ExpectedResult = $TestExpectedResult -f $number ## formats parameters so that you a substitute team numbers for ip addresses. Ex: 10.42{$number}.12
        if ($ScriptResult -match $ExpectedResult) {
            Write-Host("$TestName successful for Team $number $SourceDevice")
            $points += $AdditionalPoints
        }
        else {
            Write-Host("$TestName unsuccessful for Team $number $SourceDevice")
        }
        $TeamPoints += [PSCustomObject]@{
            Team   = "Team $number"
            Points = $points
        }
    }
    return $TeamPoints
}

##Checking Win10 connection  and configuration
##$checkWinGateway = CheckState -SourceDevice "Win10Client" -Script "Get-NetIPConfiguration | Select-Object -ExpandProperty IPv4DefaultGateway | Select-object NextHop" -Username "sysadmin" -Passwd "Change.me!" -TestName "Gateway" -TestExpectedResult "10.42.{0}.1" -AdditionalPoints 2.5  
<# $checkWinIP = CheckState -SourceDevice "Win10Client" -Script "Get-NetIPAddress | Where AddressFamily -eq 'IPv4' | Select-Object -ExpandProperty IPAddress" -Username "sysadmin" -Passwd "Change.me!" -TestName "IP address" -TestExpectedResult "10.42.{0}.12" -AdditionalPoints 2.5
$checkWinPing = CheckState -SourceDevice "Win10Client" -Script "(Test-Connection 8.8.8.8 -Count 1).StatusCode" -Username "sysadmin" -Passwd "Change.me!" -TestName "Pinging 8.8.8.8" -TestExpectedResult "0" -AdditionalPoints 2.5
$checkWinDNSPing =CheckState -SourceDevice "Win10Client" -Script "(Test-Connection dns.google -Count 1).StatusCode" -Username "sysadmin" -Passwd "Change.me!" -TestName "Pinging dns.google" -TestExpectedResult "0" -AdditionalPoints 2.5

##Checking Ubuntu connection and configuration
$checkNixIP = CheckState -SourceDevice "UbuntuClient" -Script "ip addr | grep 'inet 10'" -Username "sysadmin" -Passwd "Change.me!" -TestName "IP" -TestExpectedResult "10.42.{0}.7" -AdditionalPoints 2.5
$checkNixDNSPing = CheckState -SourceDevice "UbuntuClient" -Script "ping -c 1 dns.google &> /dev/null; echo $?" -Username "sysadmin" -Passwd "Change.me!" -TestName "Pinging dns.google" -TestExpectedResult "True" -AdditionalPoints 2.5
$checkNixPing = CheckState -SourceDevice "UbuntuClient" -Script "ping -c 1 8.8.8.8 &> /dev/null; echo $?" -Username "sysadmin" -Passwd "Change.me!" -TestName "Pinging 8.8.8.8" -TestExpectedResult "True" -AdditionalPoints 2.5
$checkNixGateway = CheckState -SourceDevice "UbuntuClient" -Script "ip route | grep 'default via'" -Username "sysadmin" -Passwd "Change.me!" -TestName "Gateway" -TestExpectedResult "10.43.{0}.1" -AdditionalPoints 2.5

##Checking Firewall Rules
$checkWinHTTP = CheckState -SourceDevice "Win10Client" -Script "(Test-NetConnection www.go.com -Port 80).TcpTestSucceeded" -Username "sysadmin" -Passwd "Change.me!" -TestName "Testing HTTP" -TestExpectedResult "True" -AdditionalPoints 2.5
$checkWinHTTPS = CheckState -SourceDevice "Win10Client" -Script "(Test-NetConnection www.ftx.com -Port 443).TcpTestSucceeded" -Username "sysadmin" -Passwd "Change.me!" -TestName "Testing HTTPS" -TestExpectedResult "True" -AdditionalPoints 2.5
$checkOutsideRDP = CheckState -SourceDevice "OutsideDevice" -Script "(Test-NetConnection 10.42.{0}.12 -Port 3389).TcpTestSucceeded" -Username "sysadmin" -Passwd "Change.me!" -TestName "Testing RDP" -TestExpectedResult "True" -AdditionalPoints 2.5
$checkOutsideSSH = CheckState -SourceDevice "OutsideDevice" -Script "(Test-NetConnection 10.43.{0}.7 -Port 22).TcpTestSucceeded" -Username "sysadmin" -Passwd "Change.me!" -TestName "Testing SSH" -TestExpectedResult "True" -AdditionalPoints 2.5
$checkOutsideWinRM= CheckState -SourceDevice "OutsideDevice" -Script "(Test-NetConnection 10.43.{0}.12 -Port 5985).TcpTestSucceeded" -Username "sysadmin" -Passwd "Change.me!" -TestName "Testing WinRM" -TestExpectedResult "True" -AdditionalPoints 2.5
$checkWinFTP = CheckState -SourceDevice "Win10Client" -Script "(Test-NetConnection bks4-speedtest-1.tele2.net -Port 21).TcpTestSucceeded" -Username "sysadmin" -Passwd "Change.me!" -TestName "Testing FTP" -TestExpectedResult "True" -AdditionalPoints 2.5
 #>
##HW4

$Array = 1..10

$Array  | Foreach-Object -ThrottleLimit 5 -Parallel {
    $checkADServerIPaddress = CheckState -SourceDevice "ADServer" -Script "Get-NetIPAddress | Where AddressFamily -eq 'IPv4' | Select-Object -ExpandProperty IPAddress" -Username "Administrator" -Passwd "Change.me!" -TestName "IP Address" -TestExpectedResult "10.42.$_.98" -AdditionalPoints 2.5
}

  #Action that will run in Parallel. Reference the current object via $PSItem and bring in outside variables with $USING:varname
#  $checkADServerIPaddress = CheckState -SourceDevice "ADServer" -Script "Get-NetIPAddress | Where AddressFamily -eq 'IPv4' | Select-Object -ExpandProperty IPAddress" -Username "Administrator" -Passwd "Change.me!" -TestName "IP Address" -TestExpectedResult "10.42.{0}.98" -AdditionalPoints 2.5
#  $checkADServerGateway = CheckState -SourceDevice "ADServer" -Script "Get-NetIPConfiguration | Select-Object -ExpandProperty IPv4DefaultGateway | Select-object NextHop" -Username "Administrator" -Passwd "Change.me!" -TestName "Gateway" -TestExpectedResult "10.42.{0}.1" -AdditionalPoints 2.5 


##Checking ADServer configuration
#$checkADServerIPaddress = CheckState -SourceDevice "ADServer" -Script "Get-NetIPAddress | Where AddressFamily -eq 'IPv4' | Select-Object -ExpandProperty IPAddress" -Username "Administrator" -Passwd "Change.me!" -TestName "IP Address" -TestExpectedResult "10.42.{0}.98" -AdditionalPoints 2.5
# -SourceDevice "ADServer" -Script "Get-NetIPAddress | Where AddressFamily -eq 'IPv4' | Select-Object -ExpandProperty IPAddress" -Username "Administrator" -Passwd "Change.me!" -TestName "IP Address" -TestExpectedResult "10.42.{0}.98" -AdditionalPoints 2.5 }

#$checkADServerGateway = CheckState -SourceDevice "ADServer" -Script "Get-NetIPConfiguration | Select-Object -ExpandProperty IPv4DefaultGateway | Select-object NextHop" -Username "Administrator" -Passwd "Change.me!" -TestName "Gateway" -TestExpectedResult "10.42.{0}.1" -AdditionalPoints 2.5 
#$checkADServerDNS = Start-Job -ScriptBlock {CheckState -SourceDevice "ADServer" -Script "Get-DNSClientServerAddress -AddressFamily IPv4 | Select-Object ServerAddresses" -Username "Administrator" -Passwd "Change.me!" -TestName "DNS" -TestExpectedResult "127.0.0.1" -AdditionalPoints 2.5 }


##Checking IISServer configuration 
<# $checkIISServerIPaddress = CheckState -SourceDevice "ADServer" -Script "Get-NetIPAddress | Where AddressFamily -eq 'IPv4' | Select-Object -ExpandProperty IPAddress" -Username "Administrator" -Passwd "Change.me!" -TestName "IP Address" -TestExpectedResult "10.42.{0}.90" -AdditionalPoints 2.5
$checkIISServerGateway = CheckState -SourceDevice "IISServer" -Script "Get-NetIPConfiguration | Select-Object -ExpandProperty IPv4DefaultGateway | Select-object NextHop" -Username "Administrator" -Passwd "Change.me!" -TestName "Gateway" -TestExpectedResult "10.42.{0}.1" -AdditionalPoints 2.5
$checkIISServerDNS = CheckState -SourceDevice"ADServer" -Script "Get-NetIPAddress | Where AddressFamily -eq 'IPv4' | Select-Object -ExpandProperty IPAddress" -Username "Administrator" -Passwd "Change.me!" -TestName "DNS" -TestExpectedResult "10.42.{0}.98" -AdditionalPoints 2.5

##Checking Win10Client DNS
$CheckWin10ClientDNS = CheckState -SourceDevice "Win10Client" -Script "Get-NetIPAddress | Where AddressFamily -eq 'IPv4' | Select-Object -ExpandProperty IPAddress" -Username "sysadmin" -Passwd "Change.me!" -TestName "Check DNS of Win10Client" -TestExpectedResult "10.42.{0}.98" -AdditionalPoints "2.5"

##Checking Domain on ADServer, IISServer, and Win10Client
$checkADServerDomain= CheckState -SourceDevice "ADServer" -Script "Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select Domain" -Username "Administrator" -Passwd "Change.me!" -TestName "Checking ADServer Domain" -TestExpectedResult "team{0}.local" -AdditionalPoints 2.5
$checkIISServerDomain= CheckState -SourceDevice "IISServer" -Script "Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select Domain" -Username "Administrator" -Passwd "Change.me!" -TestName "Checking IISServer Domain" -TestExpectedResult "team{0}.local" -AdditionalPoints 2.5
$checkWin10Domain= CheckState -SourceDevice "Win10Client" -Script "Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem | Select Domain" -Username "sysadmin" -Passwd "Change.me!" -TestName "Checking Win10 Domain" -TestExpectedResult "team{0}.local" -AdditionalPoints "2.5"

##Checking Active Directory Users
$checkADUsers = CheckState -SourceDevice "ADServer" -Script "Get-ADUser -Identity 'griffy'"  -Username "Administrator" -Passwd "Change.me!" -TestName "Finding Griffy on AD" -TestExpectedResult "True" -AdditionalPoints 5
$checkADUsers = CheckState -SourceDevice "ADServer" -Script "Get-ADUser -Identity 'QuynhCEO'" -Username "Administrator" -Passwd "Change.me!" -TestName "Finding QuynhCEO on AD" -TestExpectedResult "True" -AdditionalPoints 5

##Check if Griffy is in Administrator Group
$checkGriffyAdmin = CheckState -SourceDevice "ADServer" -Script "Get-ADGroupMember -Identity 'Adminstrators' | Select-Object 'Name'" -Username "Administrator" -Passwd "Change.me!" -TestName "Check Griffy is Admin" -TestExpectedResult "Griffy" -AdditionalPoints "2.5"

##Check if QuynhCEO is not in Administrator Group
$checkQuynhCEOAdmin = CheckState -SourceDevice "ADServer" -Script "Get-ADUser -Properties 'MemberOf' | Select-Object 'MemberOf'" -Username "Administrator" -Passwd "Change.me!" -TestName "Check QuynhCEO is not Admin" -TestExpectedResult "{}" -AdditionalPoints "2.5"

##Check if OU Gamers exists
$checkOUGamers = CheckState -SourceDevice "ADServer" -Script "GetADOrganizationalUnit -Filter {Name -eq 'Gamers'} | Select 'Name'" -Username "Administrator" -Passwd "Change.me!" -TestName "Check OU Gamers exists" -TestExpectedResult "Gamers" -AdditionalPoints "2.5"

##Check if Users are in OU Gamers
$CheckUsersInOU = CheckState -SourceDevice "ADServer" -Script "Get-ADUser -Filter "Name -eq 'Griffy'" | Select "DistinguishedName"" -Username "Administrator" -Passwd "Change.me!" -TestName 'Check Griffy in OU Gamers' -TestExpectedResult "OU=Gamers" -AdditionalPoints "2.5"
$CheckUsersInOU = CheckState -SourceDevice "ADServer" -Script "Get-ADUser -Filter "Name -eq 'QuynhCEO'" | Select "DistinguishedName"" -Username "Administrator" -Passwd "Change.me!" -TestName 'Check QuynhCEO in OU Gamers' -TestExpectedResult "OU=Gamers" -AdditionalPoints "2.5"

##Checking if OutsideDevice can access Web Server
$checkOutsidetoWebServer = CheckState -SourceDevice "OutsideDevice" -Script "(Test-NetConnection 10.42.{0}.90).TcpTestSucceeded" -Username "sysadmin" -Passwd "Change.me!" -TestName "OutsideDevice to Web Server Port 80" -TestExpectedResult "True" -AdditionalPoints "2.5"
 #>
##Do not allow any other traffic inbound to or outbound from the IIS server or AdminNet other than traffic specified as allowed in HW031
##This will be a check to make sure students have a deny all rule in the LAN net rules
Wait-Job $checkADServerIPaddress
$results = @()
$results = $checkADServerIPaddress | Group-Object -Property Team | Select-Object -Property Name, @{n = 'Points'; e = { ($_.Group | Measure-Object -Property Points -Sum).Sum } }
$results | Export-Csv -Path "Homework4_Grades.csv" -NoTypeInformation ##if your upper bound team number is set too low, it will not export to CSV.

Write-Host("Grading Homework 4 Complete!")
$endTime = Get-Date
$elapsedTime = $endTime - $startTime
Write-Host "This grading took: $($elapsedTime.TotalSeconds) seconds to run"