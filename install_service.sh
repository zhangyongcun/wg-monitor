#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # 无颜色

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}请以 root 权限运行此脚本${NC}"
  exit 1
fi

# 检查 wg-monitor 程序是否存在
WG_MONITOR_PATH="/usr/local/bin/wg-monitor-linux-amd64"
if [ ! -f "$WG_MONITOR_PATH" ]; then
  echo -e "${RED}错误: $WG_MONITOR_PATH 不存在${NC}"
  echo -e "${YELLOW}请先将 wg-monitor-linux-amd64 文件复制到 /usr/local/bin/ 目录${NC}"
  exit 1
fi

# 确保程序有执行权限
chmod +x "$WG_MONITOR_PATH"
echo -e "${GREEN}已设置 $WG_MONITOR_PATH 为可执行文件${NC}"

# 收集参数
echo -e "${YELLOW}请输入以下参数来配置 Wireguard 监控服务:${NC}"

# 获取 ping 地址
read -p "请输入需要 ping 的地址: " PING_ADDRESS
if [ -z "$PING_ADDRESS" ]; then
  echo -e "${RED}错误: ping 地址不能为空${NC}"
  exit 1
fi

# 获取接口名称
read -p "请输入 Wireguard 接口名称 (例如 wg0): " INTERFACE_NAME
if [ -z "$INTERFACE_NAME" ]; then
  echo -e "${RED}错误: 接口名称不能为空${NC}"
  exit 1
fi

# 获取可选参数
read -p "请输入检查间隔时间 (秒) [默认: 5]: " CHECK_INTERVAL
CHECK_INTERVAL=${CHECK_INTERVAL:-5}

read -p "请输入最大重试次数 [默认: 3]: " MAX_RETRIES
MAX_RETRIES=${MAX_RETRIES:-3}

# 创建 systemd 服务文件，使用接口名称区分不同服务
SERVICE_FILE="/etc/systemd/system/wg-monitor-${INTERFACE_NAME}.service"
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Wireguard 连接监控服务
After=network.target

[Service]
Type=simple
ExecStart=$WG_MONITOR_PATH --ping $PING_ADDRESS --interface $INTERFACE_NAME --interval $CHECK_INTERVAL --retries $MAX_RETRIES
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}已创建 systemd 服务文件: $SERVICE_FILE${NC}"
echo -e "${YELLOW}注意: 服务名称包含接口名称，以便区分多个监控服务${NC}"

# 重新加载 systemd 配置
systemctl daemon-reload
echo -e "${GREEN}已重新加载 systemd 配置${NC}"

# 启用并启动服务
SERVICE_NAME="wg-monitor-${INTERFACE_NAME}.service"
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

# 检查服务状态
if systemctl is-active --quiet "$SERVICE_NAME"; then
  echo -e "${GREEN}$SERVICE_NAME 服务已成功启动!${NC}"
  echo -e "${YELLOW}服务已配置为开机自启动${NC}"
  echo -e "${YELLOW}您可以使用以下命令查看服务状态:${NC}"
  echo -e "  ${GREEN}systemctl status $SERVICE_NAME${NC}"
  echo -e "${YELLOW}您可以使用以下命令查看服务日志:${NC}"
  echo -e "  ${GREEN}journalctl -u $SERVICE_NAME -f${NC}"
else
  echo -e "${RED}$SERVICE_NAME 服务启动失败${NC}"
  echo -e "${YELLOW}请使用以下命令查看错误信息:${NC}"
  echo -e "  ${GREEN}systemctl status $SERVICE_NAME${NC}"
  echo -e "  ${GREEN}journalctl -u $SERVICE_NAME${NC}"
fi
