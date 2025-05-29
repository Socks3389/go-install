交互式一键安装Golang（多版本支持）
================================
## 手动的去安装Golang语言包总是很繁琐，所以有了这个项目
### 支持Amd64、Arm64、Armv6l架构的操作系统
### 目前已测试（Amd64）：
<img width="18" height="18" src="https://www.debian.org/favicon.ico" /> Debian 11/12 
<img width="18" height="18" src="https://documentation.ubuntu.com/server/_static/favicon.png" /> Ubuntu 22.04/24.04 
<img width="18" height="18" src="https://www.centos.org/assets/icons/favicon.svg" /> CentOS 7 
##### 由于目前手上没有Arm等其他类型的机器，暂时无法进行其它架构相关测试

#### 主菜单界面
![image](https://github.com/Socks3389/go-install/blob/main/images/test-1.png?raw=true)
#### 安装界面
![image](https://github.com/Socks3389/go-install/blob/main/images/test-2.png?raw=true)
#### 帮助界面（-h 命令）
![image](https://github.com/Socks3389/go-install/blob/main/images/test-3.png?raw=true)


##### 运用:

* Wget 源码

```bash
wget https://github.com/Socks3389/go-install/raw/main/install-go.sh
```

* 基于执行权限
```bash
chmod -x install-go.sh
```

* 执行指令
```bash
bash install-go.sh
```
