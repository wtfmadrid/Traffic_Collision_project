BEGIN
CREATE USER powerbi_analyst_user WITH PASSWORD = 'DEFINE YOUR OWN PASSWORD FOR USER';
ALTER ROLE db_datareader ADD MEMBER powerbi_analyst_user;
END
