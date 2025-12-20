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

### 方案二：旧方案（包内置在镜像中）

如果您希望将包打包到镜像内部（适用于无法挂载外部存储的环境）：

```bash
# 使用 pip download 方案
docker build -f Dockerfile.pip-download -t offline-pypi:latest .

# 或使用 bandersnatch 方案
docker build -f Dockerfile -t offline-pypi:latest .

# 运行
docker run -d -p 8080:8080 --name offline-pypi offline-pypi:latest
```

## 📥 下载脚本使用说明

`download_packages.sh` 是一个功能完整的包下载脚本，支持多种选项：

```bash
# 使用默认配置下载
./download_packages.sh

# 指定输出目录
./download_packages.sh -o /data/pypi-packages

# 指定依赖文件
./download_packages.sh -r my-requirements.txt

# 使用官方 PyPI 源
./download_packages.sh -m https://pypi.org/simple/

# 查看帮助
./download_packages.sh -h
```

### 可用选项

| 选项 | 说明 | 默认值 |
|------|------|--------|
| `-r, --requirements` | requirements 文件路径 | `./requirements.txt` |
| `-o, --output` | 包输出目录 | `./packages` |
| `-p, --platforms` | 平台配置文件 | `./platforms.conf` |
| `-v, --versions` | Python 版本配置文件 | `./python_versions.conf` |
| `-m, --mirror` | PyPI 镜像源 URL | `https://mirrors.aliyun.com/pypi/simple/` |

## 🔄 更新 Python 包

使用磁盘映射方案时，更新包非常简单：

```bash
# 1. 编辑 requirements.txt 添加/修改包

# 2. 重新运行下载脚本
./download_packages.sh

# 3. 服务会自动识别新包，无需重启容器
```

## 📝 配置文件说明

### requirements.txt

指定需要下载的 Python 包：

```txt
# 核心依赖
pip
setuptools
wheel

# 科学计算
numpy
scipy
pandas

# 添加您需要的包
your-package-name
your-package==1.2.3  # 可指定版本
```

### platforms.conf

定义需要支持的目标平台：

```conf
# Linux 64位
manylinux2014_x86_64

# Windows 64位
win_amd64

# macOS（取消注释以启用）
# macosx_10_9_x86_64
# macosx_11_0_arm64
```

### python_versions.conf

定义需要支持的 Python 版本：

```conf
# Python 3.10
310

# 其他版本（取消注释以启用）
# 39
# 311
# 312
```

## 🔧 高级配置

### 远程访问

```bash
docker run -d -p 0.0.0.0:8080:8080 \
  -v $(pwd)/packages:/opt/pypi/packages:ro \
  --name offline-pypi \
  offline-pypi:latest
```

客户端配置：
```bash
pip install --index-url http://192.168.1.100:8080/simple/ \
  --trusted-host 192.168.1.100 \
  numpy
```

### 自定义包目录

```bash
# 下载到指定目录
./download_packages.sh -o /data/pypi-packages

# 挂载该目录启动服务
docker run -d -p 8080:8080 \
  -v /data/pypi-packages:/opt/pypi/packages:ro \
  --name offline-pypi \
  offline-pypi:latest
```

### Docker Compose 自定义

编辑 `docker-compose.yml` 修改配置：

```yaml
services:
  pypiserver:
    ports:
      - "9000:8080"  # 修改端口
    volumes:
      - /custom/path:/opt/pypi/packages:ro  # 自定义路径
```

## 📚 详细文档

更多详细信息，请查看 **[USER_GUIDE.md](USER_GUIDE.md)**，包括：

- 完整的使用说明
- 高级配置选项
- 故障排除指南
- 常见问题解答
- 认证配置
- 备份与恢复

## 💡 常见问题

**Q: 两种方案如何选择？**
| 方案 | 适用场景 |
|------|----------|
| 磁盘映射（推荐） | 包需要经常更新、有外部存储、开发测试环境 |
| 内置镜像 | 无法挂载外部存储、包列表固定、生产环境 |

**Q: 支持哪些操作系统？**  
A: 默认支持 Windows 64位和 Linux。可通过编辑 `platforms.conf` 文件添加更多平台。

**Q: 安装包时提示 "No matching distribution found"？**  
A: 可能原因：
1. 默认支持 Python 3.10，确保客户端版本匹配
2. 某些包可能没有预编译的 wheel 文件
3. 如需支持其他 Python 版本，编辑 `python_versions.conf`

**Q: 容器管理命令？**
```bash
docker-compose logs -f         # 查看日志
docker-compose stop            # 停止
docker-compose start           # 启动
docker-compose restart         # 重启
docker-compose down            # 停止并删除
```

## 📊 技术栈

- **基础镜像**: Python 3.10-slim
- **包管理**: pypiserver
- **服务镜像大小**: ~150 MB
- **默认端口**: 8080
