#!/bin/bash

set -e  # Exit script on any error

echo "Starting high availability database cluster setup on $(hostname)..."

# Install Pacemaker and Corosync
echo "Installing Pacemaker and Corosync..."
sudo apt-get install -y pacemaker corosync

# Enable and start Pacemaker and Corosync services
echo "Enabling and starting Pacemaker and Corosync..."
sudo systemctl enable corosync pacemaker
sudo systemctl start corosync pacemaker

# Configure Corosync cluster settings
echo "Configuring Corosync cluster settings..."
sudo cp /vagrant/conf/db_corosync.conf /etc/corosync/corosync.conf
sudo systemctl restart corosync pacemaker

if [[ "$(hostname)" == "sql1" ]]; then
    echo "Setting up cluster on sql1 using crm..."

    # Disable STONITH
    echo "Disabling STONITH..."
    sudo crm configure property stonith-enabled=false

    # Set no-quorum-policy to ignore
    echo "Configuring cluster properties..."
    sudo crm configure property no-quorum-policy=ignore
    sudo crm configure property cluster-infrastructure=corosync
    sudo crm configure property cluster-name="DBCluster"

    # Create resources
    echo "Creating resources..."

    # Virtual IP resource
    sudo crm configure primitive cluster_db_ip ocf:heartbeat:IPaddr2 \
        params ip=192.168.51.110 cidr_netmask=24 \
        op monitor interval=5s

    # MariaDB resource 
    sudo crm configure primitive mariadb ocf:heartbeat:mysqld \
        params config=/etc/mysql/my.cnf pid="/var/run/mysqld/mysqld.pid" socket="/var/run/mysqld/mysqld.sock" \
        op monitor interval=5s timeout=10s \
        op start timeout=30s interval=0 \
        op stop timeout=30s interval=0

    # Add colocation: MariaDB depends on VIP
    sudo crm configure colocation mariadb_with_vip inf: mariadb cluster_db_ip

    # Add order: VIP must start before MariaDB
    sudo crm configure order start_vip_before_mariadb Mandatory: cluster_db_ip mariadb

    # Verify cluster status
    echo "Cluster setup complete. Verifying status..."
    sudo crm status
fi

echo "High availability database cluster setup completed on $(hostname)."
