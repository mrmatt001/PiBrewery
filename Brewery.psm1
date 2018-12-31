function Install-Postgres
{
    sudo apt install postgresql libpq-dev postgresql-client postgresql-client-common -y
    sudo su postgres
    createuser pi -P --interactive
}