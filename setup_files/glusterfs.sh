#!/bin/bash

set -e  # Exit script on any error

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

    # Configuration on web1 (primary configuration node)
    if [[ "$HOSTNAME" == "web1" ]]; then
        echo "Setting up GlusterFS on web1 (primary configuration node)..."

        # Add web2 as a peer
        echo "Adding web2 as a peer..."
        sudo gluster peer probe web2 || echo "web2 is already added as a peer."

        # Create the GlusterFS volumes if they do not exist
        if ! sudo gluster volume info storage-www &>/dev/null; then
            echo "Creating GlusterFS volume (storage-www)..."
            sudo gluster volume create storage-www replica 2 transport tcp web1:/raid1/www web2:/raid1/www force
            sudo gluster volume start storage-www
        fi

        if ! sudo gluster volume info storage-sql &>/dev/null; then
            echo "Creating GlusterFS volume (storage-sql)..."
            sudo gluster volume create storage-sql replica 2 transport tcp web1:/raid1/sql web2:/raid1/sql force
            sudo gluster volume start storage-sql
        fi
    fi

    # Mount the GlusterFS volume for web directory (on web1 and web2)
    if [ ! -d "/cluster/www" ]; then
        echo "Creating /cluster/www directory for mount point..."
        sudo mkdir -p /cluster/www
    fi

    if ! grep -q "web1:/storage-www /cluster/www glusterfs" /etc/fstab; then
        echo "Adding mount for /cluster/www to /etc/fstab..."
        echo "web1:/storage-www /cluster/www glusterfs defaults,_netdev 0 0" | sudo tee -a /etc/fstab
    fi

    if ! mount | grep -q "/cluster/www"; then
        echo "Mounting the GlusterFS volume at /cluster/www..."
        sudo mount -t glusterfs web1:/storage-www /cluster/www
    fi
fi

# Configuration for SQL nodes (sql1 and sql2)
if [[ "$HOSTNAME" == "sql1" || "$HOSTNAME" == "sql2" ]]; then
    echo "Configuring GlusterFS client on SQL node ($HOSTNAME)..."

    # Mount the GlusterFS volume for SQL directory
    if [ ! -d "/cluster/sql" ]; then
        echo "Creating /cluster/sql directory for mount point..."
        sudo mkdir -p /cluster/sql
    fi

    if ! grep -q "web1:/storage-sql /cluster/sql glusterfs" /etc/fstab; then
        echo "Adding mount for /cluster/sql to /etc/fstab..."
        echo "web1:/storage-sql /cluster/sql glusterfs defaults,_netdev 0 0" | sudo tee -a /etc/fstab
    fi

    if ! mount | grep -q "/cluster/sql"; then
        echo "Mounting the GlusterFS volume at /cluster/sql..."
        sudo mount -t glusterfs web1:/storage-sql /cluster/sql
    fi
fi

echo "GlusterFS setup completed on node $HOSTNAME."