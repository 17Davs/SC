#!/bin/bash

set -e  # Exit script on any error

echo "Starting high availability cluster setup on $(hostname)..."

# Install Pacemaker and Corosync
echo "Installing Pacemaker and Corosync..."
sudo apt-get install -y pacemaker corosync sshpass fence-agents

# Enable and start Pacemaker and Corosync services
echo "Enabling and starting Pacemaker and Corosync..."
sudo systemctl enable corosync pacemaker
sudo systemctl start corosync
sudo systemctl start pacemaker

# Configure Corosync (if not already configured)
echo "Configuring Corosync cluster settings..."
sudo cp /vagrant/haproxy_corosync.conf /etc/corosync/corosync.conf

sudo systemctl restart corosync pacemaker

# Set the hacluster user password
echo "Setting password for hacluster user..."
echo "hacluster:hacluster" | sudo chpasswd

# Additional configuration for haproxy1 (cluster setup)
if [[ "$(hostname)" == "haproxy1" ]]; then
    echo "Setting up cluster on haproxy1 using crm..."
    
    # Disable STONITH (if not needed)
    echo "Disabling STONITH..."
    sudo crm configure property stonith-enabled=false

    # Create the cluster
    sudo crm configure property cluster-name="ProxyCluster"

    # Add nodes manually
    sudo crm configure node haproxy1-internal
    sudo crm configure node haproxy2-internal

    # Create resources
    echo "Creating resources..."
    sudo crm configure primitive cluster_web_ip ocf:heartbeat:IPaddr2 \
       params ip=172.20.51.1 cidr_netmask=24 nic=enp0s8 op monitor interval=5s

    sudo crm configure primitive haproxy systemd:haproxy \
        op monitor interval=5s

    # Group resources
    echo "Grouping resources..."
    sudo crm configure group g_proxy cluster_web_ip haproxy

    # Set resource constraints
    echo "Configuring resource constraints..."
    sudo crm configure location loc_haproxy1 g_proxy 100: haproxy1-internal
    sudo crm configure location loc_haproxy2 g_proxy 50: haproxy2-internal
    sudo crm configure colocation col_proxy inf: haproxy cluster_web_ip

  

    # If you want to use STONITH, uncomment the following lines:
    # sudo crm configure primitive stonith-sbd stonith:sbd op monitor interval=60s
    # sudo crm configure property stonith-enabled=true

    # Verify cluster status
    echo "Cluster setup complete. Verifying status..."
    sudo crm status
fi

echo "High availability cluster setup completed on $(hostname)."
