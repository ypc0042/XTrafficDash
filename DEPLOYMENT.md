# XTrafficDash 部署和升级指南

## 🚀 快速开始

### 1. 构建并推送Docker镜像

#### Windows用户 (PowerShell)
```powershell
# 登录Docker Hub
docker login

# 构建并推送镜像 (替换yourusername为您的Docker Hub用户名)
.\build-and-push.ps1 yourusername
```

#### Linux/Mac用户 (Bash)
```bash
# 登录Docker Hub
docker login

# 给脚本执行权限
chmod +x build-and-push.sh

# 构建并推送镜像 (替换yourusername为您的Docker Hub用户名)
./build-and-push.sh yourusername
```

### 2. VPS首次安装

在您的VPS上创建安装目录并下载配置文件：

```bash
# 创建安装目录
mkdir -p /usr/xtrafficdash
cd /usr/xtrafficdash

# 下载docker-compose.yml (替换yourusername为您的用户名)
wget https://raw.githubusercontent.com/yourusername/XTrafficDash/main/docker-compose.yml

# 修改docker-compose.yml中的镜像名
sed -i 's/sanqi37\/xtrafficdash/yourusername\/xtrafficdash/g' docker-compose.yml

# 启动服务
docker-compose up -d
```

### 3. VPS升级操作

#### 方法1：使用升级脚本 (推荐)
```bash
# 下载升级脚本
wget https://raw.githubusercontent.com/yourusername/XTrafficDash/main/upgrade.sh
chmod +x upgrade.sh

# 升级到您的镜像 (替换yourusername为您的用户名)
./upgrade.sh yourusername/xtrafficdash:latest
```

#### 方法2：手动升级
```bash
# 停止当前容器
docker stop xtrafficdash
docker rm xtrafficdash

# 拉取新镜像
docker pull yourusername/xtrafficdash:latest

# 重新启动
docker-compose up -d
```

## 📋 详细说明

### 镜像构建脚本功能
- 自动构建Docker镜像
- 推送到Docker Hub
- 错误检查和状态反馈
- 支持自定义用户名

### 升级脚本功能
- 自动备份数据库
- 停止旧容器
- 拉取新镜像
- 重新启动服务
- 健康检查

### 环境变量配置
在docker-compose.yml中可以配置：
- `PASSWORD`: 登录密码 (默认: admin123)
- `DEBUG_MODE`: 调试模式 (默认: false)
- `LOG_LEVEL`: 日志级别 (默认: info)

### 数据持久化
- 数据库文件存储在: `/usr/xtrafficdash/data/`
- 升级时会自动备份到: `./backups/`

## 🔧 故障排除

### 构建失败
1. 检查Docker是否运行
2. 检查网络连接
3. 确认Docker Hub用户名正确

### 推送失败
1. 确认已登录Docker Hub: `docker login`
2. 检查仓库权限
3. 确认镜像名格式正确

### 升级失败
1. 检查容器日志: `docker logs xtrafficdash`
2. 确认镜像存在: `docker images`
3. 检查端口占用: `netstat -tlnp | grep 37022`

## 📞 支持

如有问题，请检查：
1. Docker服务状态
2. 网络连接
3. 磁盘空间
4. 日志文件

默认访问地址: `http://your-server-ip:37022`
默认登录密码: `admin123`