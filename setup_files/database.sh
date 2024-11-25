#!/bin/bash

set -e  # Exit script on any error

echo "Installing and configuring MariaDB on $(hostname)..."

# Install MariaDB server
sudo apt-get install -y mariadb-server

# Stop MariaDB service for configuration
sudo systemctl stop mariadb

# Ensure GlusterFS mount exists
if [ ! -d "/cluster/sql" ]; then
    echo "Error: /cluster/sql does not exist. Ensure GlusterFS is properly configured before running this script."
    exit 1
fi

# Move MariaDB data directory to /cluster/sql
if [ -d "/var/lib/mysql" ]; then
    echo "Relocating MariaDB data directory to /cluster/sql..."
    if [ "$(ls -A /cluster/sql)" ]; then
        echo "/cluster/sql already populated. Skipping data migration."
    else
        # Migrate data if the directory is empty
        sudo mv /var/lib/mysql/* /cluster/sql/
    fi
    # Remove old directory and create symbolic link
    sudo rm -rf /var/lib/mysql || true  # Avoid stopping the script if the directory does not exist
    sudo ln -s /cluster/sql /var/lib/mysql
    sudo chown -R mysql:mysql /cluster/sql
    sudo chmod -R 755 /cluster/sql
fi

# Configure MariaDB to use /cluster/sql as the data directory
if ! grep -q "datadir = /cluster/sql" /etc/mysql/mariadb.conf.d/50-server.cnf; then
    echo "Updating MariaDB configuration to use /cluster/sql..."
    sudo sed -i 's|^datadir.*|datadir = /cluster/sql|' /etc/mysql/mariadb.conf.d/50-server.cnf
fi

# Configure MariaDB to bind to the cluster IP (192.168.51.110)
if ! grep -q "bind-address = 192.168.51.110" /etc/mysql/mariadb.conf.d/50-server.cnf; then
    echo "Updating MariaDB configuration to bind to 192.168.51.110..."
    sudo sed -i 's|^bind-address.*|bind-address = 192.168.51.110|' /etc/mysql/mariadb.conf.d/50-server.cnf
fi

# Restart MariaDB to apply changes
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Secure the MariaDB installation
echo "Securing MariaDB installation..."
sudo mysql_secure_installation <<EOF

Y
rootpassword
rootpassword
Y
Y
Y
Y
EOF

echo "MariaDB installation and configuration completed on $(hostname)."
