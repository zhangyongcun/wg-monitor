package main

import (
	"flag"
	"log"
	"os"
	"os/exec"
	"time"
)

// 配置参数
type Config struct {
	PingAddress   string
	Interface     string
	CheckInterval int
	MaxRetries    int
}

func main() {
	// 解析命令行参数
	config := parseFlags()

	// 设置日志
	log.SetOutput(os.Stdout)
	log.SetFlags(log.Ldate | log.Ltime)

	log.Printf("开始监控 Wireguard 接口: %s, 目标地址: %s\n", config.Interface, config.PingAddress)
	log.Printf("检查间隔: %d秒, 最大重试次数: %d\n", config.CheckInterval, config.MaxRetries)

	// 开始监控循环
	monitorWireguard(config)
}

// 解析命令行参数
func parseFlags() Config {
	pingAddress := flag.String("ping", "", "需要 ping 的地址 (必填)")
	interfaceName := flag.String("interface", "", "Wireguard 接口名称 (必填)")
	checkInterval := flag.Int("interval", 5, "检查间隔时间(秒)")
	maxRetries := flag.Int("retries", 3, "最大重试次数")

	flag.Parse()

	// 检查必填参数
	if *pingAddress == "" || *interfaceName == "" {
		flag.Usage()
		log.Fatalf("错误: ping 地址和接口名称为必填参数")
	}

	return Config{
		PingAddress:   *pingAddress,
		Interface:     *interfaceName,
		CheckInterval: *checkInterval,
		MaxRetries:    *maxRetries,
	}
}

// 监控 Wireguard 连接
func monitorWireguard(config Config) {
	for {
		// 检查连接
		if !checkConnection(config.PingAddress) {
			log.Printf("检测到连接问题: 无法 ping 通 %s\n", config.PingAddress)
			
			// 尝试重启 Wireguard
			retryCount := 0
			for retryCount < config.MaxRetries {
				log.Printf("尝试重启 Wireguard 接口 %s (尝试 %d/%d)\n", config.Interface, retryCount+1, config.MaxRetries)
				
				if restartWireguard(config.Interface) {
					// 等待一下让接口完全启动
					time.Sleep(2 * time.Second)
					
					// 检查是否恢复
					if checkConnection(config.PingAddress) {
						log.Printf("连接已恢复!\n")
						break
					}
				}
				
				retryCount++
				if retryCount >= config.MaxRetries {
					log.Printf("达到最大重试次数 (%d), 将在下一个检查周期重试\n", config.MaxRetries)
				}
			}
		} else {
			log.Printf("连接正常: %s 可达\n", config.PingAddress)
		}

		// 等待下一次检查
		time.Sleep(time.Duration(config.CheckInterval) * time.Second)
	}
}

// 检查网络连接
func checkConnection(address string) bool {
	cmd := exec.Command("ping", "-c", "1", "-W", "2", address)
	err := cmd.Run()
	return err == nil
}

// 重启 Wireguard 接口
func restartWireguard(interfaceName string) bool {
	// 关闭接口
	log.Printf("执行: wg-quick down %s\n", interfaceName)
	downCmd := exec.Command("wg-quick", "down", interfaceName)
	downErr := downCmd.Run()
	if downErr != nil {
		log.Printf("关闭接口返回错误: %v (忽略此错误)\n", downErr)
		// 忽略错误继续执行
	}

	// 等待一下确保完全关闭
	time.Sleep(1 * time.Second)

	// 启动接口
	log.Printf("执行: wg-quick up %s\n", interfaceName)
	upCmd := exec.Command("wg-quick", "up", interfaceName)
	upErr := upCmd.Run()
	if upErr != nil {
		log.Printf("启动接口返回错误: %v (忽略此错误)\n", upErr)
		// 忽略错误继续执行
	}

	// 无论命令是否成功都返回 true
	return true
}
