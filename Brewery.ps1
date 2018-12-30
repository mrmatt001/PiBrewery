Import-Module -Name Microsoft.PowerShell.IoT
Set-GpioPin -ID 4 -Value High
Set-GpioPin -ID 5 -Value High
Start-Sleep -Seconds 1
Set-GpioPin -ID 4 -Value Low
Set-GpioPin -ID 5 -Value Low
Start-Sleep -Seconds 1
Set-GpioPin -ID 4 -Value High
Set-GpioPin -ID 5 -Value High
Start-Sleep -Seconds 1
Set-GpioPin -ID 4 -Value Low
Set-GpioPin -ID 5 -Value Low
Start-Sleep -Seconds 1

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

    
    sudo python /home/pi/PiBrewery/PiRelay34Off.py
}
sudo python /home/pi/PiBrewery/PiRelay12Off.py
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
            Write-Host ("Phase 1 | Target Temp: " + $Phase1TempTarget + " | Time Remaining: " + [math]::Round(((($Phase1StartTime.AddSeconds($Phase1Timer)) - (Get-Date)).TotalSeconds),0) + " seconds")

            Write-Host ("Current temperature: " + [math]::Round(($Line.Split('=')[1] / 1000),1) + "C")
            if (($Line.Split('=')[1] / 1000) -gt $Phase1TempTarget) { $Relay = $false } else { $Relay = $true }
            Write-Host ("Relay status: " + $Relay)
        }

        if ($Relay -ne $PreviousRelay)
        {
            if ($Relay -eq $true)
            {
                Set-GpioPin -ID 4 -Value High
                sudo python /home/pi/PiBrewery/PiRelay12On.py
            }
            
            if ($Relay -eq $false)
            {
                Set-GpioPin -ID 4 -Value Low
                sudo python /home/pi/PiBrewery/PiRelay12Off.py
            }
        }

        $PreviousRelay = $Relay
    }
} until ($Phase1StartTime.AddSeconds($Phase1Timer) -lt (Get-Date))
sudo python /home/pi/PiBrewery/PiRelay12Off.py

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
                Write-Host ("Phase 2 | Target Temp: " + $Phase2TempTarget + " | Time Remaining: " + [math]::Round(((($Phase2StartTime.AddSeconds($Phase2Timer))  - (Get-Date)).TotalSeconds),0) + " seconds")
                Write-Host ("Current temperature: " + [math]::Round(($Line.Split('=')[1] / 1000),1) + "C")
                if (($Line.Split('=')[1] / 1000) -gt $Phase2TempTarget) { $Relay = $false } else { $Relay = $true }
                Write-Host ("Relay status: " + $Relay)
            }

            if ($Relay -ne $PreviousRelay)
            {
                if ($Relay -eq $true)
                {
                    Set-GpioPin -ID 5 -Value High
                    sudo python /home/pi/PiBrewery/PiRelay34On.py
                }

                if ($Relay -eq $false)
                {
                    Set-GpioPin -ID 5 -Value Low
                    sudo python /home/pi/PiBrewery/PiRelay34Off.py
                }
            }

            $PreviousRelay = $Relay
        }
    } until ($Phase2StartTime.AddSeconds($Phase2Timer) -lt (Get-Date))
    Set-GpioPin -ID 5 -Value Low
    sudo python /home/pi/PiBrewery/PiRelay34Off.py
}