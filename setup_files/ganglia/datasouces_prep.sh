#!/bin/bash

# Script to configure a Data Source for Ganglia
# Runned on Web1, web2, sql1 and sql2

echo "Updating packages..."
sudo apt update && sudo apt install -y ganglia-monitor
sudo systemctl enable ganglia-monitor

echo "Data Source preparation complete!"
