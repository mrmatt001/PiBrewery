function Install-Postgres
{
    sudo apt install postgresql libpq-dev postgresql-client postgresql-client-common -y
    sudo su postgres
    $Found = $false
    foreach ($Line in (psql -c '\l')) { if ($Line -match '^test') {$Found = $true}}
    $Found
}