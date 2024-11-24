#!/bin/bash

set -e  # Exit script on any error

echo "Starting high availability cluster setup on $(hostname)..."

# Install Pacemaker, Corosync, Pcs, and HAProxy
echo "Installing Pacemaker, Corosync, Pcs"
sudo apt-get install -y pacemaker corosync pcs 

# Enable and start services
echo "Enabling and starting Pacemaker, Corosync, and Pcs..."
sudo systemctl enable --now corosync pacemaker pcsd

# Configure Corosync (if not already configured)
echo "Configuring Corosync cluster settings..."
sudo cp /vagrant/conf/haproxy_corosync.conf /etc/corosync/corosync.conf

sudo systemctl restart corosync pacemaker

# Disable STONITH (for both nodes)
echo "Disabling STONITH..."
sudo pcs property set stonith-enabled=false

# Create the resources (HAProxy and Virtual IP)
echo "Creating resources..."

# Create the HAProxy resource
sudo pcs resource create haproxy systemd:haproxy op monitor interval=5s

# Create the Virtual IP (VIP) resource
sudo pcs resource create cluster_web_ip ocf:heartbeat:IPaddr2 \
   ip=172.20.51.1 cidr_netmask=24 op monitor interval=5s

if [[ "$(hostname)" == "haproxy1" ]]; then
    echo "Setting up cluster on haproxy1 ..."
    # Group resources (HAProxy and VIP together)
    echo "Grouping resources..."
    sudo pcs resource group add g_proxy haproxy cluster_web_ip

    # Add colocation: HAProxy depends on VIP
    sudo pcs constraint colocation add haproxy with cluster_web_ip INFINITY

    # Add order: VIP must start before HAProxy
    sudo pcs constraint order start cluster_web_ip then haproxy

    # Configure resource constraints (location constraints)
    echo "Configuring resource constraints..."
    sudo pcs constraint location g_proxy prefers haproxy1=100
    sudo pcs constraint location g_proxy prefers haproxy2=50


    # Prevent automatic migration
    echo "Setting migration-threshold to 0..."
    sudo pcs resource update haproxy meta migration-threshold=0
    sudo pcs resource update cluster_web_ip meta migration-threshold=0
fi

# Verify cluster status
echo "Cluster setup complete. Verifying status..."
sudo pcs status

echo "High availability cluster setup completed on $(hostname)."
