# 离线 Python PyPI 镜像源

这是一个轻量级的离线 Python 包仓库解决方案，适用于无互联网访问或需要本地 PyPI 镜像的环境。

## ✨ 特性

- 🚀 **快速部署**：镜像仅包含服务器，秒级启动
- 🔄 **热更新**：更新 Python 包无需重建镜像，只需重新运行下载脚本
- 💡 **轻量级**：服务镜像仅 ~150 MB
- 📦 **易于使用**：标准 pip 安装流程，无需额外配置
- 🔧 **灵活配置**：轻松自定义包列表、Python 版本、目标平台
- 🐳 **容器化部署**：基于 Docker，一键启动
- 🖥️ **多平台支持**：同时支持 Windows 和 Linux 客户端（可配置）

## 📁 项目结构

```
offline-pypi/
├── download_packages.sh      # Python 包下载脚本（主要使用）
├── Dockerfile.pypiserver     # 轻量级 pypiserver 镜像（推荐）
├── docker-compose.yml        # Docker Compose 配置
├── requirements.txt          # Python 包列表
├── platforms.conf            # 目标平台配置
├── python_versions.conf      # Python 版本配置
├── packages/                 # 下载的包存储目录（自动创建）
├── Dockerfile.pip-download   # 旧方案：包内置在镜像中
├── Dockerfile                # 旧方案：使用 bandersnatch
└── USER_GUIDE.md             # 详细使用手册
```

## 🚀 快速开始

### 方案一：推荐方案（磁盘映射）

此方案将 Python 包存储在本地目录，通过磁盘映射提供服务。**更新包时无需重建镜像**。

#### 1. 下载 Python 包

```bash
# 运行下载脚本
./download_packages.sh
```

脚本会自动：
- 读取 `requirements.txt` 中的包列表
- 根据 `platforms.conf` 下载多平台版本
- 根据 `python_versions.conf` 下载多 Python 版本
- 将所有包保存到 `./packages` 目录

#### 2. 启动服务

**使用 Docker Compose（推荐）**：
```bash
docker-compose up -d
```

**或手动运行**：
```bash
# 首先构建镜像
docker build -f Dockerfile.pypiserver -t offline-pypi:latest .

# 然后运行容器
docker run -d -p 8080:8080 \
  -v $(pwd)/packages:/opt/pypi/packages:ro \
  --name offline-pypi \
  offline-pypi:latest
```

#### 3. 验证服务

访问 http://localhost:8080/ 查看 pypiserver 欢迎页面。

#### 4. 使用 pip 安装包

**临时使用**：
```bash
pip install --index-url http://localhost:8080/simple/ --trusted-host localhost numpy
```

**配置为默认源**：
```bash
pip config set global.index-url http://localhost:8080/simple/
pip config set install.trusted-host localhost
```

之后直接使用：
```bash
pip install numpy pandas matplotlib
```