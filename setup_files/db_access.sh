#!/bin/bash

# EXECUTE ON SQLS AFTER CLUSTER SQL FULLY FUNCTIONAL AND BEFORE START CONFIGURING CACTI ON WEBS

# INITIAL CONFIGURATION
echo "Configuring MariaDB/MySQL to allow external connections from web servers..."

# Grant privileges for specific hostnames
DB_ROOT_PASS="root_password"
HOST1="web1"
HOST2="web2"

echo "Granting privileges to specific hosts ($HOST1 and $HOST2)..."
sudo mysql -u root -p$DB_ROOT_PASS -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'$HOST1' IDENTIFIED BY '$DB_ROOT_PASS' WITH GRANT OPTION;"
sudo mysql -u root -p$DB_ROOT_PASS -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'$HOST2' IDENTIFIED BY '$DB_ROOT_PASS' WITH GRANT OPTION;"
sudo mysql -u root -p$DB_ROOT_PASS -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'sql1' IDENTIFIED BY '$DB_ROOT_PASS' WITH GRANT OPTION;"
sudo mysql -u root -p$DB_ROOT_PASS -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'sql2' IDENTIFIED BY '$DB_ROOT_PASS' WITH GRANT OPTION;"
sudo mysql -u root -p$DB_ROOT_PASS -e "GRANT SELECT ON mysql.time_zone_name TO 'cactiuser'@'%';"
sudo mysql -u root -p$DB_ROOT_PASS -e "FLUSH PRIVILEGES;"
sudo mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -h 192.168.51.110 -u root -p mysql

echo "Configuration complete! The SQL server now accepts connections from $HOST1 and $HOST2."
