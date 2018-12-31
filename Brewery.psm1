function Install-Postgres
{
    sudo apt install postgresql libpq-dev postgresql-client postgresql-client-common -y
    psql -c 'CREATE DATABASE brewery;'
    sudo -u postgres psql brewery -c "create role dbuser with login password 'dbuserpwd';"
    sudo -u postgres psql brewery -c "GRANT ALL ON control TO dbuser;"
    sudo -u postgres psql brewery -c 'CREATE TABLE IF NOT EXISTS control(pk SERIAL PRIMARY KEY,Start INT NOT NULL,Stop INT NULL,TimePhase1 INT NOT NULL,TempPhase1 INT NOT NULL,TimePhase2 INT NOT NULL,TempPhase2 INT NOT NULL);'
    sudo -u postgres psql brewery -c 'INSERT INTO control(Start, Stop, TimePhase1, TempPhase1, TimePhase2, TempPhase2) VALUES (0,0,0,0,0,0)'
    sudo -u postgres psql brewery -c "GRANT ALL ON control TO dbuser;"
    sudo -u postgres psql brewery -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO dbuser;"
    Register-PackageSource -Name "nugetv2" -ProviderName NuGet -Location "http://www.nuget.org/api/v2/"
    Install-Package NpgSQL -force
}



function Read-FromPostgreSQL([STRING]$Query,[STRING]$DBServer,[STRING]$DBName,[STRING]$WhereClause,[STRING]$DBPort,[STRING]$DBUser,[STRING]$DBPassword)
{
    import-module /usr/local/share/PackageManagement/NuGet/Packages/Npgsql.4.0.4/lib/net45/Npgsql.dll
    $query = $query -f $WhereClause
    $connection = new-object Npgsql.NpgsqlConnection
    $connection.ConnectionString = "Server={0};Port={1};Database={2};User Id={3};Password={4}" -f $DBServer, $DBPort, $DBName, $DBUser, $DBPassword
    $DBCommand = $connection.CreateCommand()
    $DBCommand.CommandText = $query
    $table = new-object system.data.datatable
    $Adapter = New-Object Npgsql.NpgsqlDataAdapter ($DBCommand)
    $Adapter.Fill($table) | Out-Null
    $connection.Close() 
    Return $Table   
}


function Write-ToPostgreSQL([STRING]$Statement,[STRING]$DBServer,[STRING]$DBName,[STRING]$WhereClause,[STRING]$DBPort,[STRING]$DBUser,[STRING]$DBPassword)
{
    $Connection = new-object Npgsql.NpgsqlConnection
    $Connection.ConnectionString = "Server={0};Port={1};Database={2};User Id={3};Password={4}" -f $DBServer, $DBPort, $DBName, $DBUser, $DBPassword
    $Connection.open() 
    $DBCommand = $connection.CreateCommand()
    $DBCommand.CommandText = $Statement
    $DBCommand.ExecuteNonQuery() | Out-Null 
    $Connection.Close()
}
#Write-ToPostgreSQL -Statement $Query -DBServer localhost -DBName brewery -DBPort 5432 -DBUser dbuser -DBPassword dbuserpwd
#$Query = 'select * from control'
#Read-FromPostgreSQL -query $Query -DBServer localhost -DBName brewery -DBPort 5432 -DBUser dbuser -DBPassword dbuserpwd    