#!/bin/bash

# Initial configuration for Cacti
echo "Configuring Cacti..."

# Configure MariaDB for Cacti
DB_ROOT_PASS="root_password"
DB_NAME="cacti"
DB_USER="cactiuser"
DB_USER_PASS="cacti_password"
DB_HOST="192.168.51.110"

# Install required packages
sudo apt-get update
sudo apt-get install -y nginx php7.4-fpm php7.4-mysql php7.4-snmp php7.4-mbstring mariadb-client snmp snmpd rrdtool

# Create the Cacti database and user if they don't exist
echo "Configuring database for Cacti on the SQL cluster..."
DB_EXISTS=$(mysql -h $DB_HOST -u root -p$DB_ROOT_PASS -e "SHOW DATABASES LIKE '$DB_NAME';")
if [ -z "$DB_EXISTS" ]; then
    mysql -h $DB_HOST -u root -p$DB_ROOT_PASS -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
    mysql -h $DB_HOST -u root -p$DB_ROOT_PASS -e "CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_USER_PASS';"
    mysql -h $DB_HOST -u root -p$DB_ROOT_PASS -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';"
    mysql -h $DB_HOST -u root -p$DB_ROOT_PASS -e "FLUSH PRIVILEGES;"
else
    echo "Database $DB_NAME already exists. Skipping creation."
fi

# Install Cacti
Cacti_URL="https://www.cacti.net/downloads/cacti-latest.tar.gz"
Cacti_DIR="/cluster/www/cacti"

if [ "$(hostname)" = "web1" ]; then
    if [ ! -d $Cacti_DIR ]; then
        echo "Downloading and installing Cacti..."
        cd /tmp
        sudo wget $Cacti_URL
        sudo tar -zxvf cacti-latest.tar.gz
        sudo rm cacti-latest.tar.gz
        sudo mv cacti-* $Cacti_DIR
    else
        echo "Cacti is already downloaded and extracted."
    fi

    cd $Cacti_DIR

    # Configure Cacti database settings
    echo "Configuring Cacti database connection..."
    if [ ! -f "include/config.php" ] && [ -f "include/config.php.dist" ]; then
        sudo cp include/config.php.dist include/config.php
    fi

    sudo sed -i "s/\$database_hostname = '.*';/\$database_hostname = '$DB_HOST';/g" include/config.php
    sudo sed -i "s/\$database_username = '.*';/\$database_username = '$DB_USER';/g" include/config.php
    sudo sed -i "s/\$database_password = '.*';/\$database_password = '$DB_USER_PASS';/g" include/config.php

    # Check if database is already initialized
    TABLE_COUNT=$(mysql -h $DB_HOST -u $DB_USER -p$DB_USER_PASS -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$DB_NAME';" | tail -n 1)
    if [ "$TABLE_COUNT" -eq "0" ]; then
        echo "Importing initial Cacti data into the database..."
        if [ -f "cacti.sql" ]; then
            sudo mysql -h $DB_HOST -u $DB_USER -p$DB_USER_PASS $DB_NAME < cacti.sql
        else
            echo "Error: cacti.sql not found in $Cacti_DIR. Cannot initialize database."
            exit 1
        fi

    else
        echo "Cacti database already initialized. Skipping import and setup."
    fi
else
    echo "Skipping Cacti setup; this step is only performed on web1."
fi

# Set correct permissions
echo "Setting permissions for Cacti files..."
sudo chown -R www-data:www-data $Cacti_DIR
sudo chmod -R 755 $Cacti_DIR

# Configure Cron Job for Cacti
echo "Configuring cron job for Cacti..."
CRON_JOB="*/5 * * * * www-data php /cluster/www/cacti/poller.php > /dev/null 2>&1"
CRON_FILE="/etc/crontab"

if ! grep -Fxq "$CRON_JOB" $CRON_FILE; then
    echo "$CRON_JOB" | sudo tee -a $CRON_FILE
else
    echo "Cron job already exists in $CRON_FILE. Skipping addition."
fi

# Configure Nginx to serve Cacti
echo "Copying Nginx configuration for Cacti..."
sudo cp /vagrant/conf/nginx_default.cfg /etc/nginx/sites-available/default

# Activating the Cacti site in Nginx
echo "Activating Cacti site in Nginx..."
if [ ! -L /etc/nginx/sites-enabled/default ]; then
    sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
fi
sudo systemctl restart nginx
# Final message
echo "Cacti setup complete! Access: http://172.20.51.1/cacti to complete the installation."
