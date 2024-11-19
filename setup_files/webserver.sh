#!/bin/bash

set -e  # Exit script on any error

echo "Installing and configuring Nginx on $(hostname)..."

# Update package index
sudo apt-get update

# Install Nginx
sudo apt-get install -y nginx

# Enable and start Nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Configure the web root directory to use GlusterFS mount
if [ ! -d "/cluster/www" ]; then
    echo "Error: /cluster/www does not exist. Ensure GlusterFS is properly configured before running this script."
    exit 1
fi

# Set /cluster/www as the Nginx web root
NGINX_CONF="/etc/nginx/sites-available/default"
sudo cp $NGINX_CONF ${NGINX_CONF}.bak  # Backup the original configuration

sudo tee $NGINX_CONF > /dev/null <<EOF
server {
    listen 80;
    server_name _;

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
    echo "Creating a sample index.html in /cluster/www..."
    echo "<!DOCTYPE html>
<html>
<head>
    <title>Welcome to Nginx on $(hostname)</title>
</head>
<body>
    <h1>Welcome to $(hostname)!</h1>
    <p>This is served from /cluster/www.</p>
</body>
</html>" | sudo tee /cluster/www/index.html > /dev/null
fi

# Ensure correct permissions
sudo chown -R www-data:www-data /cluster/www
sudo chmod -R 755 /cluster/www

echo "Nginx is installed and configured to serve files from /cluster/www on $(hostname)."
