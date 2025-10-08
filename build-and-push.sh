#!/bin/bash

# XTrafficDash Docker镜像构建和推送脚本
# 使用方法: ./build-and-push.sh [your-dockerhub-username]

set -e

# 检查参数
if [ -z "$1" ]; then
    echo "错误: 请提供Docker Hub用户名"
    echo "使用方法: ./build-and-push.sh [your-dockerhub-username]"
    exit 1
fi

DOCKER_USERNAME="$1"
IMAGE_NAME="$DOCKER_USERNAME/xtrafficdash"
VERSION="latest"

echo "===== XTrafficDash Docker镜像构建和推送 ====="
echo "Docker Hub用户名: $DOCKER_USERNAME"
echo "镜像名称: $IMAGE_NAME:$VERSION"
echo ""

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "错误: Docker未运行，请先启动Docker"
    exit 1
fi

# 构建镜像
echo "🔨 开始构建Docker镜像..."
docker build -t "$IMAGE_NAME:$VERSION" .

if [ $? -eq 0 ]; then
    echo "✅ 镜像构建成功!"
else
    echo "❌ 镜像构建失败!"
    exit 1
fi

# 推送镜像
echo ""
echo "📤 开始推送镜像到Docker Hub..."
echo "请确保您已经登录Docker Hub (docker login)"

docker push "$IMAGE_NAME:$VERSION"

if [ $? -eq 0 ]; then
    echo "✅ 镜像推送成功!"
    echo ""
    echo "🎉 镜像已成功推送到: $IMAGE_NAME:$VERSION"
    echo ""
    echo "📋 VPS升级命令:"
    echo "   docker pull $IMAGE_NAME:$VERSION"
    echo "   docker stop xtrafficdash"
    echo "   docker rm xtrafficdash"
    echo "   # 然后重新运行容器或使用upgrade.sh脚本"
else
    echo "❌ 镜像推送失败!"
    echo "请检查:"
    echo "1. 是否已登录Docker Hub (docker login)"
    echo "2. 用户名是否正确"
    echo "3. 网络连接是否正常"
    exit 1
fi