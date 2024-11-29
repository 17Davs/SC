#!/bin/bash

# Initial configuration for Cacti
echo "Configuring Cacti on both web1 and web2..."

# Install required packages
sudo apt-get update
sudo apt-get install -y nginx php7.4-fpm php7.4-mysql php7.4-snmp php7.4-mbstring php-rrdtool mariadb-client snmp snmpd rrdtool

# Configure MariaDB for Cacti
DB_ROOT_PASS="root_password"
DB_NAME="cacti"
DB_USER="cactiuser"
DB_USER_PASS="cacti_password"
DB_HOST="192.168.XY.110"  # IP do MariaDB (cluster SQL)

echo "Setting up database for Cacti..."
# Create the Cacti database and user if they don't exist
sudo mysql -u root -p$DB_ROOT_PASS -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
sudo mysql -u root -p$DB_ROOT_PASS -e "CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_USER_PASS';"
sudo mysql -u root -p$DB_ROOT_PASS -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';"
sudo mysql -u root -p$DB_ROOT_PASS -e "FLUSH PRIVILEGES;"

# Install Cacti
Cacti_URL="https://www.cacti.net/downloads/cacti-latest.tar.gz"
Cacti_DIR="/cluster/www/cacti"
echo "Downloading and installing Cacti..."
cd /tmp
wget $Cacti_URL -O cacti-latest.tar.gz
tar -zxvf cacti-latest.tar.gz
sudo mv cacti-* $Cacti_DIR

# Set correct permissions
sudo chown -R www-data:www-data $Cacti_DIR
sudo chmod -R 755 $Cacti_DIR

# Configure Cacti database
echo "Configuring Cacti database..."
cd $Cacti_DIR
sudo cp include/config.php.dist include/config.php
sudo sed -i "s/\$database_type = 'mysql';/\$database_type = 'mysql';/g" include/config.php
sudo sed -i "s/\$database_hostname = 'localhost';/\$database_hostname = '$DB_HOST';/g" include/config.php
sudo sed -i "s/\$database_name = 'cacti';/\$database_name = '$DB_NAME';/g" include/config.php
sudo sed -i "s/\$database_username = 'cactiuser';/\$database_username = '$DB_USER';/g" include/config.php
sudo sed -i "s/\$database_password = 'cacti_password';/\$database_password = '$DB_USER_PASS';/g" include/config.php

# Import Cacti data into the database
echo "Importing Cacti data into the database..."
sudo php $Cacti_DIR/install/upgrade.php

# Configure Cron Job for Cacti
echo "Setting up cron job for Cacti..."
sudo crontab -l > cacti-cron
echo "*/5 * * * * php /cluster/www/cacti/poller.php > /dev/null 2>&1" >> cacti-cron
sudo crontab cacti-cron
sudo rm cacti-cron

# Configure Nginx for Cacti
echo "Configuring Nginx for Cacti..."
sudo tee /etc/nginx/sites-available/cacti <<EOF
server {
    listen 80;
    server_name _;

    root /cluster/www/cacti;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    error_log /var/log/nginx/cacti_error.log;
    access_log /var/log/nginx/cacti_access.log;
}
EOF

# Enable the site and restart Nginx
sudo ln -s /etc/nginx/sites-available/cacti /etc/nginx/sites-enabled/
sudo systemctl restart nginx

# SSL Configuration (Let's Encrypt)
echo "Configuring SSL for Cacti using Let's Encrypt..."
# Install Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Request the SSL certificate for the Cacti domain
sudo certbot --nginx -d <YOUR_DOMAIN> --non-interactive --agree-tos -m your-email@example.com

# Reload Nginx to apply SSL configuration
sudo systemctl reload nginx

echo "Cacti setup complete! You can access it at https://<IP_do_cluster>/cacti"
