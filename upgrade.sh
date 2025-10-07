#!/bin/bash

# XTrafficDash 一键升级脚本
echo "===== XTrafficDash 一键升级脚本 ====="
echo "正在停止当前容器..."

# 获取当前目录
CURRENT_DIR=$(pwd)
cd "$(dirname "$0")"

# 备份数据库
echo "正在备份数据库..."
BACKUP_DIR="./backups"
BACKUP_FILE="$BACKUP_DIR/xtrafficdash_db_$(date +%Y%m%d%H%M%S).db"
mkdir -p "$BACKUP_DIR"

# 检查数据目录是否存在
DATA_DIR="/usr/xtrafficdash/data"
if [ -d "$DATA_DIR" ]; then
    if [ -f "$DATA_DIR/xtrafficdash.db" ]; then
        cp "$DATA_DIR/xtrafficdash.db" "$BACKUP_FILE"
        echo "数据库已备份到: $BACKUP_FILE"
    else
        echo "警告: 数据库文件不存在，跳过备份"
    fi
else
    echo "警告: 数据目录不存在，跳过备份"
fi

# 停止并删除旧容器
echo "停止并删除旧容器..."
docker stop xtrafficdash
docker rm xtrafficdash

# 拉取最新镜像
echo "拉取最新镜像..."
docker pull sanqi37/xtrafficdash:latest

# 重新启动容器
echo "重新启动容器..."
if [ -f "./docker-compose.yml" ]; then
    echo "使用 docker-compose 重新启动..."
    docker-compose up -d
else
    echo "使用 docker run 重新启动..."
    docker run -d \
      --name xtrafficdash \
      -p 37022:37022 \
      -v /usr/xtrafficdash/data:/app/data \
      -e TZ=Asia/Shanghai \
      -e PASSWORD=${PASSWORD:-admin123} \
      --log-opt max-size=5m \
      --log-opt max-file=3 \
      --restart unless-stopped \
      sanqi37/xtrafficdash:latest
fi

# 检查容器是否成功启动
echo "检查容器状态..."
sleep 3
if [ "$(docker ps -q -f name=xtrafficdash)" ]; then
    echo "✅ XTrafficDash 升级成功!"
    echo "访问地址: http://$(hostname -I | awk '{print $1}'):37022"
else
    echo "❌ 容器启动失败，请检查日志:"
    docker logs xtrafficdash
fi

# 返回原目录
cd "$CURRENT_DIR"