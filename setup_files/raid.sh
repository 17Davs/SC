#!/bin/bash

set -e  # Exit on any error

# Check if the necessary disks are available
if [ ! -b /dev/sdb ] || [ ! -b /dev/sdc ]; then
    echo "Error: Required disks /dev/sdb and /dev/sdc are not available."
    exit 1
fi

# Install mdadm if not already installed
if ! dpkg -l | grep -qw mdadm; then
    echo "Installing mdadm..."
    sudo apt-get update
    sudo apt-get install -y mdadm
fi

# Stop existing RAID (if any) to avoid conflicts
if [ -b /dev/md0 ]; then
    echo "Stopping existing RAID /dev/md0..."
    sudo mdadm --stop /dev/md0 || true
    sudo mdadm --remove /dev/md0 || true
fi

# Create the RAID1 array
echo "Creating RAID1 array with /dev/sdb and /dev/sdc..."
yes | sudo mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc

# Wait for the RAID to initialize
echo "Waiting for the RAID array to initialize..."
sudo mdadm --wait /dev/md0

# Format the RAID array with ext4
echo "Formatting the RAID array with ext4 filesystem..."
sudo mkfs.ext4 /dev/md0

# Create the mount point
if [ ! -d /raid1 ]; then
    echo "Creating mount point /raid1..."
    sudo mkdir -p /raid1
fi

# Mount the RAID array
echo "Mounting the RAID array at /raid1..."
sudo mount /dev/md0 /raid1

# Update /etc/fstab for persistence
if ! grep -q "/dev/md0 /raid1 ext4" /etc/fstab; then
    echo "Adding RAID array to /etc/fstab..."
    echo "/dev/md0 /raid1 ext4 defaults 0 0" | sudo tee -a /etc/fstab
fi

# Save RAID configuration to mdadm.conf
if [ ! -f /etc/mdadm/mdadm.conf ]; then
    echo "Creating /etc/mdadm/mdadm.conf..."
    sudo mdadm --detail --scan | sudo tee /etc/mdadm/mdadm.conf
else
    echo "Updating /etc/mdadm/mdadm.conf..."
    sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
fi

# Update initramfs to include the RAID configuration
echo "Updating initramfs to include RAID configuration..."
sudo update-initramfs -u

echo "RAID1 setup completed successfully and mounted at /raid1."
