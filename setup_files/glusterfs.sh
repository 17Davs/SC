#!/bin/bash

set -e  # Exit script on any error

# Update packages
sudo apt-get update

# Install GlusterFS
echo "Installing GlusterFS..."
sudo apt-get install -y glusterfs-server glusterfs-client

# Start and enable the GlusterFS service
sudo systemctl start glusterd
sudo systemctl enable glusterd

# Get the hostname
HOSTNAME=$(hostname)

# Configuration for web nodes (web1 and web2)
if [[ "$HOSTNAME" == "web1" || "$HOSTNAME" == "web2" ]]; then
    echo "Configuring GlusterFS on web node ($HOSTNAME)..."

    # Ensure /raid1 exists and is mounted (RAID1 should already be configured)
    if ! mount | grep -q "/raid1"; then
        echo "RAID1 is not mounted on /raid1. Please ensure raid.sh is executed first."
        exit 1
    fi

    # Ensure correct permissions for /raid1
    sudo chown -R $(whoami):$(whoami) /raid1

    # Configuration on web2 (manages peer addition and volume creation)
    if [[ "$HOSTNAME" == "web2" ]]; then
        echo "Setting up GlusterFS on web2 (primary configuration node)..."

        # Add web1 as a peer
        echo "Adding web1 as a peer..."
        sudo gluster peer probe web1 || echo "web1 is already added as a peer."

        # Create the GlusterFS volume if it does not exist
        if ! sudo gluster volume info storage &>/dev/null; then
            echo "Creating GlusterFS volume (storage)..."
            sudo gluster volume create storage replica 2 transport tcp web1:/raid1 web2:/raid1
        fi

        # Start the GlusterFS volume if it is not already started
        if ! sudo gluster volume status storage &>/dev/null; then
            echo "Starting the GlusterFS volume..."
            sudo gluster volume start storage
        fi
    fi
fi

# Configuration for SQL clients (sql1 and sql2)
if [[ "$HOSTNAME" == "sql1" || "$HOSTNAME" == "sql2" ]]; then
    echo "Configuring GlusterFS client on SQL node ($HOSTNAME)..."

    # Create the mount point
    if [ ! -d "/cluster/sql" ]; then
        echo "Creating /cluster/sql directory for mount point..."
        sudo mkdir -p /cluster/sql
    fi

    # Mount the GlusterFS volume
    if ! mount | grep -q "/cluster/sql"; then
        echo "Mounting the GlusterFS volume at /cluster/sql..."
        sudo mount -t glusterfs web1:/storage /cluster/sql
    fi

    # Ensure the mount persists across reboots
    if ! grep -q "web1:/storage /cluster/sql glusterfs" /etc/fstab; then
        echo "Adding mount to /etc/fstab..."
        echo "web1:/storage /cluster/sql glusterfs defaults,_netdev 0 0" | sudo tee -a /etc/fstab
    fi
fi

# Configuration for Web clients (web1 and web2 mount /cluster/www)
if [[ "$HOSTNAME" == "web1" || "$HOSTNAME" == "web2" ]]; then
    echo "Configuring GlusterFS client for web directory on $HOSTNAME..."

    # Create the mount point
    if [ ! -d "/cluster/www" ]; then
        echo "Creating /cluster/www directory for mount point..."
        sudo mkdir -p /cluster/www
    fi

    # Mount the GlusterFS volume
    if ! mount | grep -q "/cluster/www"; then
        echo "Mounting the GlusterFS volume at /cluster/www..."
        sudo mount -t glusterfs web1:/storage /cluster/www
    fi

    # Ensure the mount persists across reboots
    if ! grep -q "web1:/storage /cluster/www glusterfs" /etc/fstab; then
        echo "Adding mount to /etc/fstab..."
        echo "web1:/storage /cluster/www glusterfs defaults,_netdev 0 0" | sudo tee -a /etc/fstab
    fi
fi

echo "GlusterFS setup completed on node $HOSTNAME."
