function Install-Postgres
{
    sudo apt-get install postgresql libpq-dev postgresql-client postgresql-client-common -y
    sudo -u postgres psql -c 'CREATE DATABASE brewery;'
    sudo -u postgres psql brewery -c "create role dbuser with login password 'dbuserpwd';"
    sudo -u postgres psql brewery -c 'CREATE TABLE IF NOT EXISTS control(pk SERIAL PRIMARY KEY,Start INT NOT NULL,Stop INT NULL,TimePhase1 INT NOT NULL,TempPhase1 INT NOT NULL,TimePhase2 INT NOT NULL,TempPhase2 INT NOT NULL);'
    sudo -u postgres psql brewery -c 'CREATE TABLE IF NOT EXISTS brews(BrewDate TIMESTAMP NOT NULL,TimePhase1 INT NOT NULL,TempPhase1 INT NOT NULL,TimePhase2 INT NOT NULL,TempPhase2 INT NOT NULL,Malt1 VarChar(200) NULL, Malt2 VarChar(200) NULL, Malt3 VarChar(200) NULL, Hops1 Varchar(200) NULL, Hops2 VarChar(200) NULL, Hops3 VarChar(200) NULL, Notes VarChar(2000) NULL);'
    sudo -u postgres psql brewery -c 'CREATE TABLE IF NOT EXISTS brewtemps(BrewDate TIMESTAMP NOT NULL,Phase INT NOT NULL,Temperature NUMERIC (4, 1) NOT NULL,Time TIMESTAMP NOT NULL);'
    sudo -u postgres psql brewery -c 'INSERT INTO control(Start, Stop, TimePhase1, TempPhase1, TimePhase2, TempPhase2) VALUES (0,0,0,0,0,0)'
    sudo -u postgres psql brewery -c "GRANT ALL ON control TO dbuser;"
    sudo -u postgres psql brewery -c "GRANT ALL ON brews TO dbuser;"
    sudo -u postgres psql brewery -c "GRANT ALL ON brewtemps TO dbuser;"
    sudo -u postgres psql brewery -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO dbuser;"
    (Get-Content /etc/postgresql/9.6/main/pg_hba.conf).replace("host    all             all             127.0.0.1/32            md5", "host    all             all             0.0.0.0/0            md5") | Set-Content /etc/postgresql/9.6/main/pg_hba.conf
    (Get-Content /etc/postgresql/9.6/main/postgresql.conf).replace("#listen_addresses = localhost", "listen_addresses = '*'") | Set-Content /etc/postgresql/9.6/main/postgresql.conf
    (Get-Content /etc/postgresql/9.6/main/postgresql.conf).replace("ssl = true                             # (change requires restart)","ssl = false                             # (change requires restart)") | Set-Content /etc/postgresql/9.6/main/postgresql.conf
    sudo service postgresql restart
    Register-PackageSource -Name "nugetv2" -ProviderName NuGet -Location "http://www.nuget.org/api/v2/"
    Install-Package NpgSQL -force
}

function Remove-Postgres
{
    sudo apt-get remove postgresql libpq-dev postgresql-client postgresql-client-common -y
    sudo -u postgres psql -c 'DROP TABLE control;'
    sudo -u postgres psql -c 'DROP TABLE brews;'
    sudo -u postgres psql -c 'DROP ROLE dbuser;'
    sudo -u postgres psql -c 'DROP DATABASE brewery;'
}

function Install-AccessPoint([STRING]$SSID,[STRING]$SSIDPassword)
{
    sudo apt-get update -y
    sudo apt-get upgrade -y
    sudo apt-get install dnsmasq hostapd samba winbind -y
    sudo systemctl stop dnsmasq
    sudo systemctl stop hostapd
    Add-Content -Path /etc/dhcpcd.conf -Value "interface wlan0"
    Add-Content -Path /etc/dhcpcd.conf -Value "    static ip_address=192.168.150.1/24"
    sudo service dhcpcd restart
    Rename-Item -Path /etc/dnsmasq.conf -NewName dnsmasq.conf.orig
    Add-Content -Path /etc/dnsmasq.conf -Value "interface=wlan0      # Use the require wireless interface - usually wlan0"
    Add-Content -Path /etc/dnsmasq.conf -Value "  dhcp-range=192.168.150.100,192.168.150.120,255.255.255.0,24h"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "interface=wlan0"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "driver=nl80211"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "ssid=$SSID"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "hw_mode=g"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "channel=7"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "wmm_enabled=0"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "macaddr_acl=0"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "auth_algs=1"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "ignore_broadcast_ssid=0"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "wpa=2"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "wpa_passphrase=$SSIDPassword"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "wpa_key_mgmt=WPA-PSK"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "wpa_pairwise=TKIP"
    Add-Content -Path /etc/hostapd/hostapd.conf -Value "rsn_pairwise=CCMP"
    (Get-Content /etc/default/hostapd).replace('#DAEMON_CONF=""','DAEMON_CONF="/etc/hostapd/hostapd.conf"') | Set-Content /etc/default/hostapd
    sudo service hostapd start  
    sudo service dnsmasq start  
    (Get-Content /etc/sysctl.conf).replace('#net.ipv4.ip_forward=1','net.ipv4.ip_forward=1') | Set-Content /etc/sysctl.conf
    sudo iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
    sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
    (Get-Content /etc/rc.local).replace('exit 0','iptables-restore < /etc/iptables.ipv4.nat') | Set-Content /etc/rc.local
    Add-Content -Path /etc/rc.local -Value "exit 0"
}

function Read-FromPostgreSQL([STRING]$Query,[STRING]$DBServer,[STRING]$DBName,[STRING]$WhereClause,[STRING]$DBPort,[STRING]$DBUser,[STRING]$DBPassword)
{
    if ($IsLinux) { import-module /usr/local/share/PackageManagement/NuGet/Packages/Npgsql.4.0.4/lib/net45/Npgsql.dll }
    if ($IsWindows) { import-module C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Npgsql\v4.0_4.0.4.0__5d8b90d52f46fda7\Npgsql.dll }
    $query = $query -f $WhereClause
    $connection = new-object Npgsql.NpgsqlConnection
    $connection.ConnectionString = "Server={0};Port={1};Database={2};User Id={3};Password={4}" -f $DBServer, $DBPort, $DBName, $DBUser, $DBPassword
    $DBCommand = $connection.CreateCommand()
    $DBCommand.CommandText = $query
    $table = new-object system.data.datatable
    $Adapter = New-Object Npgsql.NpgsqlDataAdapter ($DBCommand)
    try
    {
        $Adapter.Fill($table) | Out-Null
    }
    catch {}
    $connection.Close() 
    Return $Table   
}

function Write-ToPostgreSQL([STRING]$Statement,[STRING]$DBServer,[STRING]$DBName,[STRING]$WhereClause,[STRING]$DBPort,[STRING]$DBUser,[STRING]$DBPassword)
{
    if ($IsLinux) { import-module /usr/local/share/PackageManagement/NuGet/Packages/Npgsql.4.0.4/lib/net45/Npgsql.dll }
    if ($IsWindows) { import-module C:\Windows\Microsoft.NET\assembly\GAC_MSIL\Npgsql\v4.0_4.0.4.0__5d8b90d52f46fda7\Npgsql.dll }
    $Connection = new-object Npgsql.NpgsqlConnection
    $Connection.ConnectionString = "Server={0};Port={1};Database={2};User Id={3};Password={4}" -f $DBServer, $DBPort, $DBName, $DBUser, $DBPassword
    try
    {
        $Connection.open() 
        $DBCommand = $connection.CreateCommand()
        $DBCommand.CommandText = $Statement
        $DBCommand.ExecuteNonQuery() | Out-Null 
        $Success = $true
    }
    catch
    {
        $Success = $false
    }
    $Connection.Close()
    Return $Success
}
### Examples

#INSERT
#$Statement = 'INSERT INTO control(Start, Stop, TimePhase1, TempPhase1, TimePhase2, TempPhase2) VALUES (0,0,0,0,0,0)'
#Write-ToPostgreSQL -Statement $Statement -DBServer localhost -DBName brewery -DBPort 5432 -DBUser dbuser -DBPassword dbuserpwd

#SELECT
#$Query = 'select * from control'
#Read-FromPostgreSQL -query $Query -DBServer localhost -DBName brewery -DBPort 5432 -DBUser dbuser -DBPassword dbuserpwd    