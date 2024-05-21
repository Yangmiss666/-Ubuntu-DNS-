脚本功能
获取网卡名称：自动检测系统中的主要网卡。
备份现有配置文件：对 netplan 和 systemd-resolved 的配置文件进行备份。
修改 netplan 配置：如果系统使用 netplan，脚本会修改配置文件并应用新配置。
修改 systemd-resolved 配置：如果系统使用 systemd-resolved，脚本会修改配置文件并重启 systemd-resolved 服务，同时确保 /etc/resolv.conf 是指向正确位置的符号链接。
此脚本旨在覆盖大多数常见的DNS配置场景，确保在不同环境下都能正确应用DNS设置。
