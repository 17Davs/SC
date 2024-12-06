#!/bin/bash
# execute on web machines after cacti_prep.sh 

# Update packages and repositories
echo "Updating packages and repositories..."
sudo apt update && sudo apt upgrade -y

# Install necessary PHP extensions
echo "Installing necessary PHP extensions..."
sudo apt install -y php7.4-snmp php7.4-xml php7.4-mbstring php7.4-mysqli php7.4-pdo php7.4-pdo-mysql \
    php7.4-sockets php7.4-ldap php7.4-gd php7.4-gmp php7.4-intl
sudo apt install php php-mysql php-snmp php-xml phpmbstring php-gd rrdtool snmp

# Configure timezone in PHP
echo "Configuring timezone in PHP..."
PHP_INI_APACHE="/etc/php/7.4/apache2/php.ini"
PHP_INI_CLI="/etc/php/7.4/cli/php.ini"

for PHP_INI in $PHP_INI_APACHE $PHP_INI_CLI; do
    sudo sed -i "s|^;date.timezone =.*|date.timezone = Europe/Lisbon|g" $PHP_INI
    sudo sed -i "s|^max_execution_time =.*|max_execution_time = 300|g" $PHP_INI
done

# Restart PHP and Apache services
echo "Restarting PHP and Apache services..."
sudo systemctl restart php7.4-fpm
sudo systemctl restart apache2

# Verify PHP extensions installation
echo "Verifying installed PHP modules..."
php -m | grep -E "snmp|xml|mbstring|mysqli|pdo|pdo_mysql|sockets|ldap"

# Complete installation
echo "Local server configuration completed! Configure the database remotely to finalize."
