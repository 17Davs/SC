#!/bin/bash

# Variables with the IPs and names of the servers
web1="192.168.51.121 web1"
web2="192.168.51.122 web2"

sql1="192.168.51.111 sql1"
sql2="192.168.51.112 sql2"

haproxy1_internal="192.168.51.100 haproxy1-internal"
haproxy1_external="172.20.51.200 haproxy1-external"
haproxy2_internal="192.168.51.101 haproxy2-internal"
haproxy2_external="172.20.51.201 haproxy2-external"

cluster_sql="192.168.51.110 cluster-sql"

# Function to check and add entry to /etc/hosts
add_to_hosts() {
    local entry="$1"
    local ip_name=(${entry})
    local ip=${ip_name[0]}
    local name=${ip_name[1]}

    if ! grep -q "$ip" /etc/hosts; then
        echo "Adding $name to /etc/hosts"
        echo "$entry" | sudo tee -a /etc/hosts > /dev/null
    else
        echo "$name is already in /etc/hosts"
    fi
}

# Ensure 127.0.0.1 is properly configured for localhost
echo "Configuring localhost entry in /etc/hosts..."
if grep -q "127.0." /etc/hosts; then
    sudo sed -i 's|^127\.0\..*|127.0.0.1 localhost|' /etc/hosts
else
    echo "127.0.0.1 localhost" | sudo tee -a /etc/hosts > /dev/null
fi

# Identify the current hostname
hostname=$(hostname)

# Check the type of server and add the appropriate IPs
case $hostname in
    "web1" | "web2")
        add_to_hosts "$web1"
        add_to_hosts "$web2"
        ;;
    "sql1" | "sql2")
        add_to_hosts "$web1"
        add_to_hosts "$web2"
        add_to_hosts "$sql1"
        add_to_hosts "$sql2"
        ;;
    "haproxy1" | "haproxy2")
        add_to_hosts "$web1"
        add_to_hosts "$web2"
        add_to_hosts "$haproxy1_internal"
        add_to_hosts "$haproxy1_external"
        add_to_hosts "$haproxy2_internal"
        add_to_hosts "$haproxy2_external"
        ;;
    *)
        echo "Hostname not recognized. No entries were added."
        ;;
esac

echo "Configuration of /etc/hosts completed!"
