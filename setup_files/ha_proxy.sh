#!/bin/bash

set -e  # Exit script on any error

echo "Starting HAProxy setup on $(hostname)..."

# Install HAProxy
echo "Installing HAProxy..."
sudo apt-get install -y haproxy

# Stop HAProxy service for configuration
echo "Stopping HAProxy service..."
sudo systemctl stop haproxy

# Backup the default HAProxy configuration file
echo "Backing up the default HAProxy configuration file..."
sudo mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak

# Copy the custom HAProxy configuration file
echo "Copying custom HAProxy configuration..."
sudo cp /vagrant/haproxy.cfg /etc/haproxy/haproxy.cfg

# Restart and enable HAProxy
echo "Restarting and enabling HAProxy service..."
sudo systemctl enable haproxy
sudo systemctl start haproxy

echo "HAProxy setup completed on $(hostname)."
