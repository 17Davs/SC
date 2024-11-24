#!/bin/bash

set -e  # Exit script on any error

echo "Starting HAProxy setup on $(hostname)..."

# Install HAProxy
echo "Installing HAProxy..."
sudo apt-get install -y haproxy

# Copy the custom HAProxy configuration file
echo "Copying custom HAProxy configuration..."
sudo cp /vagrant/conf/haproxy.cfg /etc/haproxy/haproxy.cfg

# Restart and enable HAProxy
echo "Restarting and enabling HAProxy service..."
sudo systemctl enable haproxy
sudo systemctl restart haproxy

echo "HAProxy setup completed on $(hostname)."
