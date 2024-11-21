#!/bin/bash

set -e  # Exit script on any error

echo "Starting high availability cluster setup on $(hostname)..."

# Install Pacemaker, Corosync, and pcs
echo "Installing Pacemaker, Corosync, and pcs..."
sudo apt-get install -y pacemaker corosync pcs

# Enable and start Pacemaker and Corosync services
echo "Enabling and starting Pacemaker and Corosync..."
sudo systemctl enable corosync pacemaker
sudo systemctl start corosync
sudo systemctl start pacemaker

# Configure Corosync (if not already configured)
if [ ! -f "/etc/corosync/corosync.conf" ]; then
    echo "Configuring Corosync cluster settings..."
    sudo tee /etc/corosync/corosync.conf > /dev/null <<EOF
totem {
    version: 2
    secauth: on
    cluster_name: ProxyCluster
    transport: udpu
    interface {
        ringnumber: 0
        bindnetaddr: 172.20.51.0  # Adjust to the external network
        mcastport: 5405
    }
}
nodelist {
    node {
        ring0_addr: haproxy1
        nodeid: 1
    }
    node {
        ring0_addr: haproxy2
        nodeid: 2
    }
}
quorum {
    provider: corosync_votequorum
}
logging {
    to_logfile: yes
    logfile: /var/log/corosync.log
    to_syslog: yes
}
EOF
    sudo systemctl restart corosync pacemaker
fi

# Additional configuration for haproxy1 (cluster setup)
if [[ "$(hostname)" == "haproxy1" ]]; then
    echo "Setting up cluster on haproxy1..."

    # Set the hacluster user password
    echo "Setting password for hacluster user..."
    echo "hacluster:hacluster" | sudo chpasswd

    # Authenticate with both nodes
    echo "Authenticating with haproxy1 and haproxy2..."
    sudo pcs cluster auth haproxy1 haproxy2 -u hacluster -p hacluster --force

    # Create and start the cluster
    echo "Creating and starting the cluster..."
    sudo pcs cluster setup --name ProxyCluster haproxy1 haproxy2
    sudo pcs cluster start --all

    # Enable the cluster to start on boot
    echo "Enabling the cluster to start on boot..."
    sudo pcs cluster enable --all

    # Create Virtual IP resource
    echo "Creating Virtual IP resource..."
    sudo pcs resource create cluster_web_ip ocf:heartbeat:IPaddr2 ip=172.20.51.1 cidr_netmask=24 nic=eth1 op monitor interval=5s

    # Create HAProxy resource
    echo "Creating HAProxy resource..."
    sudo pcs resource create haproxy systemd:haproxy op monitor interval=5s

    # Group resources
    echo "Grouping resources..."
    sudo pcs resource group add g_proxy cluster_web_ip haproxy

    # Set location preferences
    echo "Configuring resource location preferences..."
    sudo pcs constraint location g_proxy prefers haproxy1=100
    sudo pcs constraint location g_proxy prefers haproxy2=50

    # Configure colocation constraints
    echo "Configuring colocation for HAProxy and Virtual IP..."
    sudo pcs constraint colocation add haproxy with cluster_web_ip INFINITY

    # Prevent automatic migration
    echo "Setting migration-threshold to 0..."
    sudo pcs resource update haproxy meta migration-threshold=0
    sudo pcs resource update cluster_web_ip meta migration-threshold=0

    # Verify cluster status
    echo "Cluster setup complete. Verifying status..."
    sudo pcs status
fi

echo "High availability cluster setup completed on $(hostname)."
