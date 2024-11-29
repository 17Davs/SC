#!/bin/bash

set -e  # Exit script on any error

# Installing necessary packages
echo "Installing required packages..."
sudo apt install -y nginx php-fpm php-mysql snmp snmpd rrdtool mariadb-client unzip wget

# Restarting essential services
echo "Restarting services..."
sudo systemctl restart nginx php7.4-fpm

# Database configuration on the SQL cluster
DB_HOST="192.168.51.110"
DB_NAME="cacti"
DB_USER="cactiuser"
DB_PASS="cacti_password"
DB_ROOT_PASS="root_password"

# Configure database (only on web1)
echo "Configuring database on the SQL cluster ..."
# Check if the database already exists
DB_EXISTS=$(mysql -h $DB_HOST -u root -p$DB_ROOT_PASS -e "SHOW DATABASES LIKE '$DB_NAME';")
if [ -z "$DB_EXISTS" ]; then
    mysql -h $DB_HOST -u root -p$DB_ROOT_PASS -e "CREATE DATABASE $DB_NAME;"
    mysql -h $DB_HOST -u root -p$DB_ROOT_PASS -e "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';"
    mysql -h $DB_HOST -u root -p$DB_ROOT_PASS -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';"
    mysql -h $DB_HOST -u root -p$DB_ROOT_PASS -e "FLUSH PRIVILEGES;"
else
    echo "Database $DB_NAME already exists. Skipping creation."
fi

# Download and configure Cacti (only on web1)
echo "Downloading and configuring Cacti..."
if [ "$(hostname)" = "web1" ]; then
  cd /cluster/www
  if [ ! -d "cacti" ]; then
    sudo wget https://www.cacti.net/downloads/cacti-latest.tar.gz
    sudo tar -zxvf cacti-latest.tar.gz
    sudo rm cacti-latest.tar.gz
    sudo mv cacti-* cacti
  else
    echo "Cacti is already downloaded and extracted."
  fi

  # Configuring Cacti database settings
  echo "Configuring Cacti database connection..."
  if [ -f /cluster/www/cacti/include/config.php.dist ]; then
    sudo cp /cluster/www/cacti/include/config.php.dist /cluster/www/cacti/include/config.php
  fi
  sudo sed -i "s/\$database_username = 'cacti'/\$database_username = '$DB_USER'/" /cluster/www/cacti/include/config.php
  sudo sed -i "s/\$database_password = ''/\$database_password = '$DB_PASS'/" /cluster/www/cacti/include/config.php
  sudo sed -i "s/\$database_hostname = 'localhost'/\$database_hostname = '$DB_HOST'/" /cluster/www/cacti/include/config.php
else
  echo "Skipping Cacti setup; this step is only performed on web1."
fi



# Adjusting permissions
echo "Adjusting permissions..."
sudo chown -R www-data:www-data /cluster/www/cacti
sudo chmod -R 775 /cluster/www/cacti

# Configuring cron job for Cacti
echo "Configuring cron job for Cacti..."
echo "*/5 * * * * www-data php /cluster/www/cacti/poller.php > /dev/null 2>&1" | sudo tee -a /etc/crontab

# Configuring Nginx to serve Cacti
echo "Copying Nginx configuration for Cacti..."
sudo cp /vagrant/conf/nginx_cacti.cfg /etc/nginx/sites-available/cacti

# Activating the Cacti site in Nginx
echo "Activating Cacti site in Nginx..."
if [ ! -L /etc/nginx/sites-enabled/cacti ]; then
  sudo ln -s /etc/nginx/sites-available/cacti /etc/nginx/sites-enabled/
  sudo systemctl restart nginx
else
  echo "Cacti site already activated. Skipping activation."
fi

# Final message
echo "Cacti setup complete! Access: http://172.20.51.1/cacti to complete the installation."
