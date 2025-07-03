#!/bin/bash

# Define an array of servers with their static IPs
# Format: "ip_address"
declare -a SERVERS=(
  "192.168.122.35"
  "192.168.122.189"
  "192.168.122.251"
  "192.168.122.38"
  "192.168.122.107"
  "192.168.122.44"
)

GATEWAY="192.168.122.1"
DNS_SERVER="192.168.122.1"
SSH_USER="ds"
INTERFACE="enp1s0"
NETPLAN_FILE="/etc/netplan/50-cloud-init.yaml"

# Loop through each server
for ip_address in "${SERVERS[@]}"; do
  echo "🔄 Connecting to server: $ip_address"

  # Use SSH to run setup commands on remote host
  ssh ${SSH_USER}@${ip_address} <<EOF

    echo "🔐 Disabling cloud-init network config..."
    echo "network: {config: disabled}" | sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg > /dev/null

    echo "📄 Backing up current netplan config..."
    sudo cp $NETPLAN_FILE $NETPLAN_FILE.bak

    echo "📝 Writing new static IP configuration..."
    cat <<NETPLAN | sudo tee $NETPLAN_FILE > /dev/null
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - $ip_address/24
      gateway4: $GATEWAY
      nameservers:
        addresses:
          - $DNS_SERVER
NETPLAN

    echo "🔁 Applying netplan configuration..."
    sudo netplan apply

    echo "✅ Successfully configured $ip_address"
EOF

  echo "✅ Completed setup on $ip_address"
  echo "----------------------------"
done

echo "🎉 All servers configured with static IPs!"
