Param(
        [Parameter(Mandatory=$true)][STRING]$DBUser,
        [Parameter(Mandatory=$true)][SecureString]$DBPassword,
        $WriteToPostgres = $true,
        [STRING]$DBServer = "pibrewery"
        )

Import-Module -Name Microsoft.PowerShell.IoT
Import-Module /home/pi/PiBrewery/PiBrewery.psm1
$Counter = 0
do
{
    $Counter++
    Set-GpioPin -ID 4 -Value High
    Set-GpioPin -ID 5 -Value High
    Start-Sleep -MilliSeconds 500
    Set-GpioPin -ID 4 -Value Low
    Set-GpioPin -ID 5 -Value Low
    Start-Sleep -MilliSeconds 500

} until ($Counter -eq 5)
Clear-Host
do
{
    $Valid = $false
    $Phase1Timer = Read-Host "Enter Phase 1 time (in seconds): "
    if (($Phase1Timer -match '^[0-9]') -and ($Phase1Timer -notmatch '[a-zA-Z.]')) {$Valid = $true}
} until ($Valid -eq $true)

do
{
    $Valid = $false
    $Phase1TempTarget = Read-Host "Enter Phase 1 target temperature: "
    if (($Phase1TempTarget -match '^[0-9]') -and ($Phase1TempTarget -notmatch '[a-zA-Z.]')) {$Valid = $true}
} until ($Valid -eq $true)

if ((Get-ChildItem /sys/bus/w1/devices/ | Where-Object {$_.Name -match '^28'}).Count -eq '2')
{
    do
    {
        $Valid = $false
        $Phase2Timer = Read-Host "Enter Phase 2 time (in seconds): "
        if (($Phase2Timer -match '^[0-9]') -and ($Phase2Timer -notmatch '[a-zA-Z.]')) {$Valid = $true}
    } until ($Valid -eq $true)

    do
    {
        $Valid = $false
        $Phase2TempTarget = Read-Host "Enter Phase 2 target temperature: "
        if (($Phase2TempTarget -match '^[0-9]') -and ($Phase2TempTarget -notmatch '[a-zA-Z.]')) {$Valid = $true}
    } until ($Valid -eq $true)

    Set-GpioPin -Id 0 -Value Low  #Relay 3 - GPIO Pin 11
    Set-GpioPin -Id 7 -Value Low  #Relay 4 - GPIO Pin 7
}
if ($WriteToPostgres -eq $true)
{
    $UnsecurePassword = (New-Object PSCredential "user",$DBPassword).GetNetworkCredential().Password
    $BrewDate = (Get-Date)
    $SQLUpdateStatement = "INSERT INTO brews(BrewDate, TimePhase1, TempPhase1, TimePhase2, TempPhase2) VALUES ('$BrewDate','$Phase1Timer','$Phase2TempTarget','$Phase2Timer','$Phase2TempTarget')"
    $SQLInsert = Write-ToPostgreSQL -Statement $SQLUpdateStatement -DBServer $DBServer -DBName brewery -DBPort 5432 -DBUser $DBUser -DBPassword $UnsecurePassword
}

Set-GpioPin -id 3 -Value Low   #Relay 1 - GPIO Pin 15
Set-GpioPin -id 2 -Value Low   #Relay 2 - GPIO Pin 13
sudo modprobe w1-gpio
sudo modprobe w1-therm
$Phase1StartTime = (Get-Date)
$Relay = $false
$PreviousRelay = $true
$Thermometer1 = "/sys/bus/w1/devices/" + (Get-ChildItem /sys/bus/w1/devices/ | Where-Object {$_.Name -match '^28'}).Name[0] + "/w1_slave"
do
{
    foreach ($Line in (Get-Content $Thermometer1))
    {
        Clear-Host
        if ($Line -match 't=')
        {
            Write-Host ("Phase 1 | Target Temp: " + $Phase1TempTarget + "C | Time Remaining: " + [math]::Round(((($Phase1StartTime.AddSeconds($Phase1Timer)) - (Get-Date)).TotalSeconds),0) + " seconds")
            $Temperature = [math]::Round(($Line.Split('=')[1] / 1000),1)
            Write-Host ("Current temperature: " + $Temperature + "C")
            if (($Line.Split('=')[1] / 1000) -gt $Phase1TempTarget) { $Relay = $false } else { $Relay = $true }
            Write-Host ("Relay status: " + $Relay)
        }

        if ($Relay -ne $PreviousRelay)
        {
            if ($Relay -eq $true)
            {
                Set-GpioPin -ID 4 -Value High  #LED 1   - GPIO Pin 16
                Set-GpioPin -id 3 -Value High  #Relay 1 - GPIO Pin 15
                Set-GpioPin -id 2 -Value High  #Relay 2 - GPIO Pin 13
            }
            
            if ($Relay -eq $false)
            {
                Set-GpioPin -ID 4 -Value Low   #LED 1   - GPIO Pin 16
                Set-GpioPin -id 3 -Value Low   #Relay 1 - GPIO Pin 15
                Set-GpioPin -id 2 -Value Low   #Relay 2 - GPIO Pin 13
            }
        }
        if ($WriteToPostgres -eq $true)
        {
            $ReadingTime = (Get-Date)
            $SQLUpdateStatement = "INSERT INTO brewtemps(BrewDate, Phase, Temperature, Time) VALUES ('$BrewDate','1','$Temperature','$ReadingTime')"
            $SQLInsert = Write-ToPostgreSQL -Statement $SQLUpdateStatement -DBServer $DBServer -DBName brewery -DBPort 5432 -DBUser $DBUser -DBPassword $UnsecurePassword
        }
    $PreviousRelay = $Relay
    Start-Sleep -Seconds 1
    }
} until ($Phase1StartTime.AddSeconds($Phase1Timer) -lt (Get-Date))
Set-GpioPin -ID 4 -Value Low   #LED 1   - GPIO Pin 16
Set-GpioPin -id 3 -Value Low   #Relay 1 - GPIO Pin 15
Set-GpioPin -id 2 -Value Low   #Relay 2 - GPIO Pin 13

if ((Get-ChildItem /sys/bus/w1/devices/ | Where-Object {$_.Name -match '^28'}).Count -eq '2')
{
    $Thermometer2 = "/sys/bus/w1/devices/" + (Get-ChildItem /sys/bus/w1/devices/ | Where-Object {$_.Name -match '^28'}).Name[1] + "/w1_slave"
    $Relay = $false
    $PreviousRelay = $true
    $Phase2StartTime = (Get-Date)
    do
    {
        foreach ($Line in (Get-Content $Thermometer2))
        {
            Clear-Host
            if ($Line -match 't=')
            {
                Write-Host ("Phase 2 | Target Temp: " + $Phase2TempTarget + "C | Time Remaining: " + [math]::Round(((($Phase2StartTime.AddSeconds($Phase2Timer))  - (Get-Date)).TotalSeconds),0) + " seconds")
                $Temperature = [math]::Round(($Line.Split('=')[1] / 1000),1)
                Write-Host ("Current temperature: " + $Temperature + "C")
                if (($Line.Split('=')[1] / 1000) -gt $Phase2TempTarget) { $Relay = $false } else { $Relay = $true }
                Write-Host ("Relay status: " + $Relay)
            }

            if ($Relay -ne $PreviousRelay)
            {
                if ($Relay -eq $true)
                {
                    Set-GpioPin -Id 5 -Value High  #LED 2   - GPIO Pin 18
                    Set-GpioPin -Id 0 -Value High  #Relay 3 - GPIO Pin 11
                    Set-GpioPin -Id 7 -Value High  #Relay 4 - GPIO Pin 7
                }

                if ($Relay -eq $false)
                {
                    Set-GpioPin -Id 5 -Value Low  #LED 2   - GPIO Pin 18
                    Set-GpioPin -Id 0 -Value Low  #Relay 3 - GPIO Pin 11
                    Set-GpioPin -Id 7 -Value Low  #Relay 4 - GPIO Pin 7
                }
            }

            if ($WriteToPostgres -eq $true)
            {
                $ReadingTime = (Get-Date)
                $SQLUpdateStatement = "INSERT INTO brewtemps(BrewDate, Phase, Temperature, Time) VALUES ('$BrewDate','2','$Temperature','$ReadingTime')"
                $SQLInsert = Write-ToPostgreSQL -Statement $SQLUpdateStatement -DBServer $DBServer -DBName brewery -DBPort 5432 -DBUser $DBUser -DBPassword $UnsecurePassword
            }
            $PreviousRelay = $Relay
            Start-Sleep -Seconds 1
        }
    } until ($Phase2StartTime.AddSeconds($Phase2Timer) -lt (Get-Date))
    Set-GpioPin -Id 5 -Value Low  #LED 2   - GPIO Pin 18
    Set-GpioPin -Id 0 -Value Low  #Relay 3 - GPIO Pin 11
    Set-GpioPin -Id 7 -Value Low  #Relay 4 - GPIO Pin 7
}