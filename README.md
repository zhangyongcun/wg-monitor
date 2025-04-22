# Wireguard 监控工具

[![GitHub Release](https://img.shields.io/github/v/release/zhangyongcun/wg-monitor)](https://github.com/zhangyongcun/wg-monitor/releases)
[![Go Report Card](https://goreportcard.com/badge/github.com/zhangyongcun/wg-monitor)](https://goreportcard.com/report/github.com/zhangyongcun/wg-monitor)
[![License](https://img.shields.io/github/license/zhangyongcun/wg-monitor)](https://github.com/zhangyongcun/wg-monitor/blob/main/LICENSE)

这是一个用 Go 语言编写的 Wireguard 监控工具，用于自动检测 Wireguard VPN 连接状态并在需要时重启接口。当检测到连接问题时，工具会自动执行 `wg-quick down` 和 `wg-quick up` 命令来重启 Wireguard 接口，确保网络连接的可靠性。

## 功能特点

- 定期检查指定地址的连通性（通过 ping）
- 当连接失败时，自动重启 Wireguard 接口
- 可配置的检查间隔和重试次数
- 详细的日志输出
- 支持作为系统服务运行（通过提供的安装脚本）
- 支持监控多个 Wireguard 接口（每个接口创建独立的服务）

## 下载

您可以从 [GitHub Releases](https://github.com/zhangyongcun/wg-monitor/releases) 页面下载预编译的二进制文件，支持以下平台：

- Linux (amd64, arm64, arm)

## 使用方法

### 命令行参数

```
wg-monitor --ping <IP地址> --interface <接口名称> [--interval <间隔秒数>] [--retries <重试次数>]
```

参数说明：

- `--ping`：必填，要 ping 的目标地址（通常是 Wireguard 服务器或网络内的某个地址）
- `--interface`：必填，Wireguard 接口名称（例如 wg0）
- `--interval`：可选，检查间隔时间（秒），默认为 5 秒
- `--retries`：可选，连接失败时的最大重试次数，默认为 3 次

### 运行示例

```bash
# 基本用法
sudo ./wg-monitor --ping 10.0.0.1 --interface wg0

# 自定义检查间隔和重试次数
sudo ./wg-monitor --ping 10.0.0.1 --interface wg0 --interval 10 --retries 5
```

## 安装为系统服务

在 Linux 系统上，您可以使用提供的 `install_service.sh` 脚本将 wg-monitor 安装为系统服务：

1. 将编译好的 wg-monitor 程序复制到 `/usr/local/bin/`：
   ```bash
   sudo cp wg-monitor-linux-amd64 /usr/local/bin/
   ```

2. 运行安装脚本：
   ```bash
   sudo ./install_service.sh
   ```

3. 按照提示输入必要的参数（ping 地址、接口名称等）

脚本会创建一个 systemd 服务，并设置为开机自启动。服务名称格式为 `wg-monitor-<接口名称>.service`，这样可以为多个 Wireguard 接口创建不同的监控服务。

### 服务管理命令

```bash
# 查看服务状态
systemctl status wg-monitor-wg0.service

# 启动服务
systemctl start wg-monitor-wg0.service

# 停止服务
systemctl stop wg-monitor-wg0.service

# 查看日志
journalctl -u wg-monitor-wg0.service -f
```

## 从源码编译

### 前提条件

- Go 1.18 或更高版本

### 编译步骤

```bash
# 克隆仓库
git clone https://github.com/zhangyongcun/wg-monitor.git
cd wg-monitor

# 编译当前平台版本
go build -o wg-monitor

# 交叉编译 Linux AMD64 版本
GOOS=linux GOARCH=amd64 go build -o wg-monitor-linux-amd64
```

## 注意事项

- 需要以 root 权限运行，因为 wg-quick 命令需要管理员权限
- 确保系统已安装 Wireguard 工具（wg-quick）
- 程序会忽略 wg-quick 命令可能返回的错误，确保重启过程不会因错误而中断

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目。

## 许可证

[MIT License](LICENSE)
