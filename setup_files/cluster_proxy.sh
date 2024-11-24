#!/bin/bash

set -e  # Exit script on any error

echo "Starting high availability cluster setup on $(hostname)..."

# Install Pacemaker and Corosync
echo "Installing Pacemaker and Corosync..."
sudo apt-get install -y pacemaker corosync 

# Enable and start Pacemaker and Corosync services
echo "Enabling and starting Pacemaker and Corosync..."
sudo systemctl enable corosync pacemaker
sudo systemctl start corosync
sudo systemctl start pacemaker

# Configure Corosync
echo "Configuring Corosync cluster settings..."
sudo cp /vagrant/conf/haproxy_corosync.conf /etc/corosync/corosync.conf

sudo systemctl restart corosync pacemaker

# Additional configuration for haproxy1 (cluster setup)
if [[ "$(hostname)" == "haproxy1" ]]; then
    echo "Setting up cluster on haproxy1 using crm..."
    
    # Disable STONITH 
    echo "Disabling STONITH and configuring quorum policy..."
    sudo crm configure property stonith-enabled=false
    sudo crm configure property no-quorum-policy=ignore

    # Set cluster infrastructure details
    sudo crm configure property cluster-infrastructure="corosync"

    # Create the cluster
    sudo crm configure property cluster-name="ProxyCluster"

    # Create resources
    echo "Creating resources..."
    sudo crm configure primitive cluster_web_ip ocf:heartbeat:IPaddr2 \
       params ip=172.20.51.1 cidr_netmask=24 op monitor interval=5s

    sudo crm configure primitive haproxy systemd:haproxy op monitor interval=5s

    # Add colocation: HAProxy depends on VIP
    sudo crm configure colocation proxy_with_vip inf: haproxy cluster_web_ip

    # Add order: VIP must start before HAProxy
    sudo crm configure order start_vip_before_haproxy Mandatory: cluster_web_ip haproxy

    # Verify cluster status
    echo "Cluster setup complete. Verifying status..."
    sudo crm status
fi

echo "High availability cluster setup completed on $(hostname)."
