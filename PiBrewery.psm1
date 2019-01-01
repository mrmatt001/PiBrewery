function Install-Postgres
{
    sudo apt-get install postgresql libpq-dev postgresql-client postgresql-client-common -y
    sudo -u postgres psql -c 'CREATE DATABASE brewery;'
    sudo -u postgres psql brewery -c "create role dbuser with login password 'dbuserpwd';"
    sudo -u postgres psql brewery -c 'CREATE TABLE IF NOT EXISTS control(pk SERIAL PRIMARY KEY,Start INT NOT NULL,Stop INT NULL,TimePhase1 INT NOT NULL,TempPhase1 INT NOT NULL,TimePhase2 INT NOT NULL,TempPhase2 INT NOT NULL);'
    sudo -u postgres psql brewery -c 'CREATE TABLE IF NOT EXISTS brews(BrewDate TIMESTAMP NOT NULL,TimePhase1 INT NOT NULL,TempPhase1 INT NOT NULL,TimePhase2 INT NOT NULL,TempPhase2 INT NOT NULL,Malt1 VarChar(200) NULL, Malt2 VarChar(200) NULL, Malt3 VarChar(200) NULL, Hops1 Varchar(200) NULL, Hops2 VarChar(200) NULL, Hops3 VarChar(200) NULL, Notes VarChar(2000) NULL);'
    sudo -u postgres psql brewery -c 'CREATE TABLE IF NOT EXISTS brewtemps(BrewDate TIMESTAMP NOT NULL,Phase INT NOT NULL,Temperature NUMERIC (5, 2) NOT NULL,Time TIMESTAMP NOT NULL);'
    sudo -u postgres psql brewery -c 'INSERT INTO control(Start, Stop, TimePhase1, TempPhase1, TimePhase2, TempPhase2) VALUES (0,0,0,0,0,0)'
    sudo -u postgres psql brewery -c "GRANT ALL ON control TO dbuser;"
    sudo -u postgres psql brewery -c "GRANT ALL ON brews TO dbuser;"
    sudo -u postgres psql brewery -c "GRANT ALL ON brewtemps TO dbuser;"
    sudo -u postgres psql brewery -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO dbuser;"
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
    import-module /usr/local/share/PackageManagement/NuGet/Packages/Npgsql.4.0.4/lib/net45/Npgsql.dll
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