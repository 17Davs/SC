#!/bin/bash

set -e  # Exit script on any error

echo "Setting up high availability on $(hostname)..."

# Install Pacemaker, Corosync, and Pcs
sudo apt install -y pacemaker corosync pcs

# Enable and start Pacemaker and Corosync services
sudo systemctl enable corosync pacemaker
sudo systemctl start corosync
sudo systemctl start pacemaker

# Backup and configure Corosync cluster configuration file
if [ ! -f "/etc/corosync/corosync.conf" ]; then
    echo "Configuring Corosync..."
    sudo cp /etc/corosync/corosync.conf /etc/corosync/corosync.conf.bak || true
    sudo tee /etc/corosync/corosync.conf > /dev/null <<EOF
totem {
    version: 2
    secauth: on
    cluster_name: SQLCluster
    transport: udpu
    interface {
        ringnumber: 0
        bindnetaddr: 192.168.51.0  
        mcastport: 5405
    }
}
nodelist {
    node {
        ring0_addr: sql1
        nodeid: 1
    }
    node {
        ring0_addr: sql2
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

# Configure pcs authentication and cluster creation (only on sql1)
if [[ "$(hostname)" == "sql1" ]]; then
    echo "Configuring pcs authentication and cluster on sql1..."

    # Set the hacluster user password
    echo "hacluster:hacluster" | sudo chpasswd

    # Authenticate with both nodes
    sudo pcs cluster auth sql1 sql2 -u hacluster -p hacluster --force

    # Create and start the cluster
    sudo pcs cluster setup --name SQLCluster sql1 sql2
    sudo pcs cluster start --all

    # Enable the cluster to start on boot
    sudo pcs cluster enable --all

    # Configure Virtual IP resource
    echo "Creating Virtual IP resource..."
    sudo pcs resource create virtualip ocf:heartbeat:IPaddr2 ip=192.168.51.110 cidr_netmask=24 op monitor interval=5s

    # Create MariaDB resource using systemd
    echo "Creating MariaDB resource using systemd..."
    sudo pcs resource create mariadb systemd:mariadb op monitor interval=5s

    # Add resources to a group
    echo "Adding resources to a group..."
    sudo pcs resource group add g_mariadb virtualip mariadb

    # Set location preferences for failover
    echo "Configuring resource location preferences..."
    sudo pcs constraint location g_mariadb prefers sql1=100
    sudo pcs constraint location g_mariadb prefers sql2=50

    # Add colocation constraint for MariaDB and Virtual IP to stay together
    echo "Configuring colocation for MariaDB and Virtual IP..."
    sudo pcs constraint colocation add mariadb with virtualip INFINITY

    # Set migration-threshold to 0 to prevent automatic migration
    echo "Setting migration-threshold to 0 for both MariaDB and Virtual IP..."
    sudo pcs resource update mariadb meta migration-threshold=0
    sudo pcs resource update virtualip meta migration-threshold=0

    # Verify the cluster status
    echo "Cluster configuration completed. Current status:"
    sudo pcs status
fi

echo "High availability setup with pcs completed on $(hostname)."
