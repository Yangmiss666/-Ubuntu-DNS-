#!/bin/bash

# 定义要设置的DNS服务器地址
DNS1="1.1.1.1"
DNS2="1.0.0.1"

# 获取网卡名称（假设系统中只有一个主要网卡）
INTERFACE=$(ip route get 1 | grep -o 'dev.*' | awk '{print $2}')

# 检查网卡名称是否找到
if [ -z "$INTERFACE" ]; then
    echo "Network interface not found. Please check your network configuration."
    exit 1
fi

# 定义netplan配置文件路径
NETPLAN_CONFIG="/etc/netplan/01-network-manager-all.yaml"

# 备份文件函数
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        sudo cp "$file" "${file}.bak"
    fi
}

# 修改netplan配置
modify_netplan() {
    echo "Modifying netplan configuration..."
    backup_file "$NETPLAN_CONFIG"
    
    sudo tee "$NETPLAN_CONFIG" > /dev/null <<EOL
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    $INTERFACE:
      dhcp4: true
      nameservers:
        addresses: [$DNS1, $DNS2]
EOL

    sudo netplan apply
    if [ $? -eq 0 ]; then
        echo "Netplan configuration updated successfully."
    else
        echo "Failed to apply netplan configuration."
        exit 1
    fi
}

# 修改systemd-resolved配置
modify_systemd_resolved() {
    echo "Modifying systemd-resolved configuration..."
    SYSTEMD_RESOLVED_CONFIG="/etc/systemd/resolved.conf"
    backup_file "$SYSTEMD_RESOLVED_CONFIG"

    sudo sed -i "s/^#DNS=/DNS=$DNS1 $DNS2/" "$SYSTEMD_RESOLVED_CONFIG"
    sudo sed -i "s/^#FallbackDNS=/FallbackDNS=1.1.1.1 1.0.0.1/" "$SYSTEMD_RESOLVED_CONFIG"

    sudo systemctl restart systemd-resolved
    if [ $? -eq 0 ]; then
        echo "systemd-resolved configuration updated successfully."
    else
        echo "Failed to restart systemd-resolved."
        exit 1
    fi

    # Ensure /etc/resolv.conf is a symlink to the resolved.conf file
    sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
}

# 检查是否使用netplan
if [ -f "$NETPLAN_CONFIG" ]; then
    modify_netplan
else
    echo "Netplan configuration file not found: $NETPLAN_CONFIG"
fi

# 检查是否使用systemd-resolved
if systemctl is-active --quiet systemd-resolved; then
    modify_systemd_resolved
else
    echo "systemd-resolved is not active."
fi

echo "DNS configuration script completed."
