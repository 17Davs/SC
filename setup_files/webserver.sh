#!/bin/bash

# This script installs and configures Nginx on the web server node.
# Ensure GlusterFS is properly configured before running this script.

set -e  # Exit script on any error

echo "Installing and configuring Nginx on $(hostname)..."

# Install Nginx
sudo apt-get install -y nginx
# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Ensure /cluster/www exists
if [ ! -d "/cluster/www" ]; then
    echo "Error: /cluster/www does not exist. Ensure GlusterFS is properly configured before running this script."
    exit 1
fi

# Set /cluster/www as the Nginx web root (just for now)
NGINX_CONF="/etc/nginx/sites-available/default"
sudo tee $NGINX_CONF > /dev/null <<EOF
server {
    listen 80;
    server_name default;

    root /cluster/www;
    index index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
# Reload Nginx to apply the configuration
sudo systemctl reload nginx

# Create a sample index.html file in /cluster/www
if [ ! -f "/cluster/www/index.html" ]; then
    echo "Creating index.html in /cluster/www..."
    sudo cp /vagrant/index.html /cluster/www/index.html
fi

# Ensure correct permissions
sudo chown -R www-data:www-data /cluster/www
sudo chmod -R 755 /cluster/www

echo "Nginx is installed and configured to serve files from /cluster/www on $(hostname)."
