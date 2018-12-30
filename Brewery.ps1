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

sudo python /home/pi/PiRelay12Off.py
sudo python /home/pi/PiRelay34Off.py
sudo modprobe w1-gpio
sudo modprobe w1-therm
$Phase1StartTime = (Get-Date)
$Relay = $false
$PreviousRelay = $true
do
{
    foreach ($Line in (Get-Content /sys/bus/w1/devices/28-031581ce23ff/w1_slave))
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
                sudo python /home/pi/PiRelay12On.py
            }

            {
                sudo python /home/pi/PiRelay12Off.py
            }
        }

        $PreviousRelay = $Relay
    }
} until ($Phase1StartTime.AddSeconds($Phase1Timer) -lt (Get-Date))
sudo python /home/pi/PiRelay12Off.py

$Relay = $false
$PreviousRelay = $true
$Phase2StartTime = (Get-Date)
do
{
    foreach ($Line in (Get-Content /sys/bus/w1/devices/28-031581d75cff/w1_slave))
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
                sudo python /home/pi/PiRelay34On.py
            }


            if ($Relay -eq $false)
            {
                sudo python /home/pi/PiRelay34Off.py
            }
        }

        $PreviousRelay = $Relay
    }
} until ($Phase2StartTime.AddSeconds($Phase2Timer) -lt (Get-Date))
sudo python /home/pi/PiRelay34Off.py