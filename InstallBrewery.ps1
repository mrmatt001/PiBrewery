<#
sudo rpi-update
Raspi-config
sudo apt-get install libunwind8
wget https://github.com/PowerShell/PowerShell/releases/download/v6.2.0-preview.3/powershell-6.2.0-preview.3-linux-arm32.tar.gz

mkdir /home/pi/powershell
tar -xvf /home/pi/powershell-6.2.0-preview.3-linux-arm32.tar.gz -C /home/pi/powershell

sudo nano /etc/ssh/sshd_config
add line:

Subsystem powershell /home/pi/powershell/pwsh -sshs -NoLogo -NoProfile

Need IR receiver (Media Center receiver) plugged into Raspberry Pi

Install Raspbian on pi
:set new Password for Pi
:Set to autologon


sudo nano /home/pi/.bashrc
!!!at end...
:echo Launching PowerShell Script
:sudo /home/pi/powershell/pwsh /home/pi/powershell/Script1.ps1
CTRL+X > Y > return

sudo nano /home/pi/powershell/Script1.ps1
$ScriptComplete = $false
Clear-Host
Write-Host "Listening..."
do
{
   $KeyPressed = $Host.UI.RawUI.ReadKey()
   Clear-Host
   $KeyPressed.VirtualKeyCode
   Write-Host "Listening"
   if ($KeyPressed.VirtualKeyCode -eq '37')
   {
       Write-Host "Left arrow has been pressed. Treat as turn on."
       $Counter++
   }

   if ($KeyPressed.VirtualKeyCode -eq '39')
   {
       Write-Host "Right arrow has been pressed. Treat as turn off."
   }

   if ($KeyPressed.VirtualKeyCode -eq '40')
   {
       Write-Host "Down arrow has been pressed. Treat as kill script."
       $ScriptComplete = $true
   }

} until ($ScriptComplete -eq $true)

Write-Host "Script completed"
CTRL+X > Y > return

echo "export WIRINGPI_CODES=1"|sudo tee -a /etc/profile.d/WiringPiCodes.sh
sudo WIRINGPI_CODES=1 /home/pi/powershell/pwsh
Install-Module Microsoft.PowerShell.IoT -Force
Import-Module Microsoft.PowerShell.IoT

Install-Package NpgSQL
import-module /usr/local/share/PackageManagement/NuGet/Packages/Npgsql.4.0.4/lib/net45/Npgsql.dll

function getDBConnection ($MyDBServer, $MyDBPort, $MyDatabase, $MyUid, $MyPwd) {
$DBConnectionString = "server=$MyDBServer;port=$MyDBPort;user id=$MyUid;password=$MyPwd;database=$MyDatabase;pooling=false"
$DBConn = New-Object Npgsql.NpgsqlConnection;
$DBConn.ConnectionString = $DBConnectionString
$DBConn.Open()

return $DBConn
}

function closeDBConnection ($DBConn)
{
    $DBConn.Close
}

$MyDBConnection = getDBConnection 192.168.50.11 5432 "Brewery" "postgres" "Password123"
$query = "SELECT * FROM Control;"
$DBCmd = $MyDBConnection.CreateCommand()
$DBCmd.CommandText = $query
$adapter = New-Object -TypeName Npgsql.NpgsqlDataAdapter $DBCmd
$dataset = New-Object -TypeName System.Data.DataSet
$adapter.Fill($dataset)
$dataset.Tables[0]
closeDBConnection($MyDBConnection)
#>