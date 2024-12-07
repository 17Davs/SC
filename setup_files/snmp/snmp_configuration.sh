#!/bin/bash

# SCRIPT TO CONFIGURE SNMP ON MACHINES THAT WILL BE USED IN CACTI

# Update the package list and install SNMP
echo "Updating packages and installing SNMP..."
sudo apt update -y && apt install -y snmp snmpd

# Configure the snmpd.conf file
echo "Configuring SNMP..."

sudo cp /vagrant/snmp/snmpd.conf /etc/snmp/snmpd.conf

# Restart the SNMP service to apply the configurations
echo "Restarting the SNMP service..."
systemctl restart snmpd
systemctl enable snmpd

# Check if the service is active
if systemctl is-active --quiet snmpd; then
     echo "SNMP configured and running correctly."
else
     echo "There was a problem configuring SNMP. Check the service status."
fi

# Display the SNMP port being used
echo "Check if port 161 is in use:"
ss -tuln | grep :161

# Finish
echo "Configuration complete. Make sure the firewall allows access to port 161."
