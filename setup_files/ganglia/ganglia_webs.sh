#!/bin/bash

# NGINX FILE already configured
# Runned on web1 and web2 only
# Script to configure Ganglia on Web servers

echo "Updating packages and installing dependencies..."
sudo apt update
sudo apt install -y ganglia-monitor gmetad ganglia-webfrontend
sudo systemctl enable gmetad

# Check if shared directory /cluster/www/ganglia already exists
if [ ! -d "/cluster/www/ganglia" ]; then
    echo "Preparing shared directory /cluster/www/ganglia..."
    sudo mkdir -p /cluster/www/ganglia
    sudo cp -r /usr/share/ganglia-webfrontend/* /cluster/www/ganglia/

    # Configuring gmetad
    echo "Configuring gmetad.conf..."
    sudo cp /vagrant/ganglia/gmetad.conf /cluster/www/ganglia/gmetad.conf
    sudo cp /vagrant/ganglia/gmond.conf /cluster/www/ganglia/gmond.conf
    
else
    echo "/cluster/www/ganglia already exists. Skipping shared directory setup..."
fi

#if symbolic links do not exist, create them
if [ ! -L "/etc/ganglia/gmond.conf" ]; then
    echo "Creating symbolic link for /cluster/www/ganglia/gmond.conf..."
    sudo ln -s /cluster/www/ganglia/gmond.conf /etc/ganglia/gmond.conf
else
    echo "Symbolic link for /etc/ganglia/gmond.conf already exists. Skipping..."
fi

if [ ! -L "/etc/ganglia/gmetad.conf" ]; then
    echo "Creating symbolic link for /cluster/www/ganglia/gmetad.conf..."
    sudo ln -s /cluster/www/ganglia/gmetad.conf /etc/ganglia/gmetad.conf
else
    echo "Symbolic link for /etc/ganglia/gmetad.conf already exists. Skipping..."
fi

# Restarting services
echo "Restarting Ganglia services..."
sudo systemctl restart ganglia-monitor
sudo systemctl restart gmetad
sudo systemctl restart nginx

echo "Ganglia configuration complete on $(hostname)!"
