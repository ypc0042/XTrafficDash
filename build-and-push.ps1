# XTrafficDash Docker镜像构建和推送脚本 (PowerShell版本)
# 使用方法: .\build-and-push.ps1 [your-dockerhub-username]

param(
    [Parameter(Mandatory=$true)]
    [string]$DockerUsername
)

$IMAGE_NAME = "$DockerUsername/xtrafficdash"
$VERSION = "latest"

Write-Host "===== XTrafficDash Docker镜像构建和推送 =====" -ForegroundColor Cyan
Write-Host "Docker Hub用户名: $DockerUsername" -ForegroundColor Green
Write-Host "镜像名称: $IMAGE_NAME`:$VERSION" -ForegroundColor Green
Write-Host ""

# 检查Docker是否运行
try {
    docker info | Out-Null
} catch {
    Write-Host "错误: Docker未运行，请先启动Docker" -ForegroundColor Red
    exit 1
}

# 构建镜像
Write-Host "🔨 开始构建Docker镜像..." -ForegroundColor Yellow
docker build -t "$IMAGE_NAME`:$VERSION" .

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 镜像构建成功!" -ForegroundColor Green
} else {
    Write-Host "❌ 镜像构建失败!" -ForegroundColor Red
    exit 1
}

# 推送镜像
Write-Host ""
Write-Host "📤 开始推送镜像到Docker Hub..." -ForegroundColor Yellow
Write-Host "请确保您已经登录Docker Hub (docker login)" -ForegroundColor Cyan

docker push "$IMAGE_NAME`:$VERSION"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 镜像推送成功!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🎉 镜像已成功推送到: $IMAGE_NAME`:$VERSION" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 VPS升级命令:" -ForegroundColor Yellow
    Write-Host "   docker pull $IMAGE_NAME`:$VERSION" -ForegroundColor White
    Write-Host "   docker stop xtrafficdash" -ForegroundColor White
    Write-Host "   docker rm xtrafficdash" -ForegroundColor White
    Write-Host "   # 然后重新运行容器或使用upgrade.sh脚本" -ForegroundColor Gray
} else {
    Write-Host "❌ 镜像推送失败!" -ForegroundColor Red
    Write-Host "请检查:" -ForegroundColor Yellow
    Write-Host "1. 是否已登录Docker Hub (docker login)" -ForegroundColor White
    Write-Host "2. 用户名是否正确" -ForegroundColor White
    Write-Host "3. 网络连接是否正常" -ForegroundColor White
    exit 1
}