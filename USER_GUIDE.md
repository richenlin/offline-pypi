# 离线 Python 仓库使用手册

## 📖 目录

- [快速开始](#快速开始)
- [下载脚本使用](#下载脚本使用)
- [运行容器](#运行容器)
- [使用 pip 安装包](#使用-pip-安装包)
- [高级配置](#高级配置)
- [维护与更新](#维护与更新)
- [常见问题](#常见问题)
- [故障排除](#故障排除)

---

## 快速开始

### 1. 克隆或下载项目

```bash
git clone <repository-url>
cd offline-pypi
```

### 2. 下载 Python 包

```bash
./download_packages.sh
```

脚本会自动：
- 读取 `requirements.txt` 中的包列表
- 根据 `platforms.conf` 下载多平台版本
- 根据 `python_versions.conf` 下载多 Python 版本
- 将所有包保存到 `./packages` 目录

下载时间约 5-10 分钟，取决于网络速度和包数量。

### 3. 启动服务

**使用 Docker Compose（推荐）**：

```bash
docker-compose up -d
```

**或手动运行**：

```bash
# 构建镜像
docker build -f Dockerfile.pypiserver -t offline-pypi:latest .

# 运行容器
docker run -d -p 8080:8080 \
  -v $(pwd)/packages:/opt/pypi/packages:ro \
  --name offline-pypi \
  offline-pypi:latest
```

### 4. 验证服务

在浏览器中访问 `http://localhost:8080/`，应该能看到 pypiserver 的欢迎页面。

### 5. 测试安装

```bash
pip install --index-url http://localhost:8080/simple/ --trusted-host localhost numpy
```

---

## 下载脚本使用

`download_packages.sh` 是一个功能完整的包下载脚本，支持多种选项。

### 基本用法

```bash
# 使用默认配置下载
./download_packages.sh
```

### 命令行选项

```bash
./download_packages.sh [选项]

选项:
  -r, --requirements FILE   指定 requirements.txt 文件 (默认: ./requirements.txt)
  -o, --output DIR          指定输出目录 (默认: ./packages)
  -p, --platforms FILE      指定平台配置文件 (默认: ./platforms.conf)
  -v, --versions FILE       指定 Python 版本配置文件 (默认: ./python_versions.conf)
  -m, --mirror URL          指定 PyPI 镜像源 (默认: https://mirrors.aliyun.com/pypi/simple/)
  -h, --help                显示帮助信息
```

### 使用示例

```bash
# 指定输出目录
./download_packages.sh -o /data/pypi-packages

# 指定依赖文件
./download_packages.sh -r my-requirements.txt

# 使用官方 PyPI 源
./download_packages.sh -m https://pypi.org/simple/

# 组合使用
./download_packages.sh -r custom.txt -o /data/packages -m https://pypi.tuna.tsinghua.edu.cn/simple/
```

### 配置文件说明

#### requirements.txt

指定需要下载的 Python 包：

```text
# 核心依赖
pip
setuptools
wheel

# 科学计算
numpy
scipy
pandas
matplotlib
scikit-learn

# 你的自定义包
your-package-name
your-package==1.2.3  # 可指定版本
```

#### platforms.conf

定义需要支持的操作系统平台：

```text
# 平台配置文件
# 每行一个平台标签，注释行以 # 开头

# Linux 64位（默认启用）
manylinux2014_x86_64

# Windows 64位（默认启用）
win_amd64

# Windows 32位（取消注释以启用）
# win32

# macOS Intel（取消注释以启用）
# macosx_10_9_x86_64

# macOS Apple Silicon（取消注释以启用）
# macosx_11_0_arm64
```

**常用平台标签**：

| 平台 | 标签 |
|------|------|
| Linux 64位 | `manylinux2014_x86_64` 或 `manylinux_2_17_x86_64` |
| Windows 64位 | `win_amd64` |
| Windows 32位 | `win32` |
| macOS Intel | `macosx_10_9_x86_64` |
| macOS ARM | `macosx_11_0_arm64` |

#### python_versions.conf

定义需要支持的 Python 版本：

```text
# Python 版本配置文件
# 每行一个版本号，格式: 主版本+次版本

# Python 3.10 (默认启用)
310

# Python 3.11 (取消注释以启用)
# 311

# Python 3.12 (取消注释以启用)
# 312

# Python 3.9 (取消注释以启用)
# 39
```

**常用版本号**：

| Python 版本 | 配置值 |
|-------------|--------|
| Python 3.8  | `38`   |
| Python 3.9  | `39`   |
| Python 3.10 | `310`  |
| Python 3.11 | `311`  |
| Python 3.12 | `312`  |
| Python 3.13 | `313`  |

> **注意**：启用多个版本和平台会增加下载时间和磁盘占用。

---

## 运行容器

### 方法一：Docker Compose（推荐）

```bash
# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f

# 停止服务
docker-compose down
```

### 方法二：手动运行

#### 基本运行

```bash
docker run -d -p 8080:8080 \
  -v $(pwd)/packages:/opt/pypi/packages:ro \
  --name offline-pypi \
  offline-pypi:latest
```

#### 使用自定义端口

```bash
docker run -d -p 9000:8080 \
  -v $(pwd)/packages:/opt/pypi/packages:ro \
  --name offline-pypi \
  offline-pypi:latest
```

然后通过 `http://localhost:9000/` 访问。

#### 后台运行与自动重启

```bash
docker run -d \
  -p 8080:8080 \
  -v $(pwd)/packages:/opt/pypi/packages:ro \
  --name offline-pypi \
  --restart unless-stopped \
  offline-pypi:latest
```

#### 资源限制

```bash
docker run -d -p 8080:8080 \
  -v $(pwd)/packages:/opt/pypi/packages:ro \
  --name offline-pypi \
  --memory="512m" \
  --cpus="0.5" \
  offline-pypi:latest
```

---

## 使用 pip 安装包

### 方法 1: 一次性使用

```bash
pip install --index-url http://localhost:8080/simple/ \
  --trusted-host localhost \
  PACKAGE_NAME
```

**示例**：

```bash
pip install --index-url http://localhost:8080/simple/ \
  --trusted-host localhost \
  numpy pandas matplotlib
```

### 方法 2: 配置为默认源（推荐）

**全局配置**：

```bash
pip config set global.index-url http://localhost:8080/simple/
pip config set install.trusted-host localhost
```

配置后，直接使用 `pip install` 即可：

```bash
pip install numpy pandas
```

**项目级配置**：

在项目根目录创建 `pip.conf`（Linux/macOS）或 `pip.ini`（Windows）：

```ini
[global]
index-url = http://localhost:8080/simple/
trusted-host = localhost
```

### 方法 3: 在 requirements.txt 中指定

```bash
# requirements.txt
--index-url http://localhost:8080/simple/
--trusted-host localhost

numpy
pandas
matplotlib
```

然后安装：

```bash
pip install -r requirements.txt
```

### 方法 4: 在虚拟环境中使用

```bash
# 创建虚拟环境
python3 -m venv myenv
source myenv/bin/activate  # Linux/macOS
# 或 myenv\Scripts\activate  # Windows

# 配置 pip
pip config set global.index-url http://localhost:8080/simple/
pip config set install.trusted-host localhost

# 安装包
pip install numpy
```

---

## Windows 客户端使用指南

本镜像服务支持 Windows 客户端，以下是详细的使用方法。

### 前提条件

- Windows 10/11
- Python 3.10 已安装
- 能够访问运行 pypiserver 的服务器

### 方法 1: 命令提示符 (CMD)

**临时使用**：

```cmd
pip install --index-url http://SERVER_IP:8080/simple/ --trusted-host SERVER_IP numpy
```

**配置为默认源**：

```cmd
pip config set global.index-url http://SERVER_IP:8080/simple/
pip config set install.trusted-host SERVER_IP
```

配置后直接使用：

```cmd
pip install numpy pandas matplotlib
```

### 方法 2: PowerShell

**临时使用**：

```powershell
pip install --index-url http://SERVER_IP:8080/simple/ --trusted-host SERVER_IP numpy
```

**配置为默认源**：

```powershell
pip config set global.index-url http://SERVER_IP:8080/simple/
pip config set install.trusted-host SERVER_IP
```

### 方法 3: 使用 pip.ini 配置文件

在 Windows 上，pip 配置文件位于：
- 用户级：`%APPDATA%\pip\pip.ini`
- 全局级：`C:\ProgramData\pip\pip.ini`

创建或编辑 `%APPDATA%\pip\pip.ini`：

```ini
[global]
index-url = http://SERVER_IP:8080/simple/
trusted-host = SERVER_IP
```

> 将 `SERVER_IP` 替换为实际的服务器 IP 地址，如 `192.168.1.100`

### 方法 4: 在 Windows 虚拟环境中使用

```cmd
:: 创建虚拟环境
python -m venv myenv

:: 激活虚拟环境
myenv\Scripts\activate

:: 配置 pip 源
pip config set global.index-url http://SERVER_IP:8080/simple/
pip config set install.trusted-host SERVER_IP

:: 安装包
pip install numpy pandas
```

### 方法 5: 使用 requirements.txt

创建 `requirements.txt` 文件：

```text
--index-url http://SERVER_IP:8080/simple/
--trusted-host SERVER_IP

numpy
pandas
matplotlib
```

然后安装：

```cmd
pip install -r requirements.txt
```

### Windows 常见问题

**Q: 提示 "No matching distribution found"？**

可能原因：
1. Python 版本不匹配 - 确保使用 Python 3.10
2. 检查 Python 版本：`python --version`

**Q: 连接超时？**

1. 检查防火墙是否允许访问 8080 端口
2. 确认服务器 IP 地址正确
3. 测试连接：在浏览器中访问 `http://SERVER_IP:8080/`

**Q: SSL 证书错误？**

确保添加了 `--trusted-host` 参数，或在 pip.ini 中配置。

---

## 高级配置

### 远程访问

如果需要从其他机器访问 pypiserver：

```bash
docker run -d -p 0.0.0.0:8080:8080 \
  -v $(pwd)/packages:/opt/pypi/packages:ro \
  --name offline-pypi \
  offline-pypi:latest
```

然后在客户端使用服务器 IP：

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

### 启用认证

1. 创建密码文件：

```bash
# 安装 htpasswd 工具
apt-get install apache2-utils  # Debian/Ubuntu
# 或 yum install httpd-tools   # CentOS/RHEL

# 创建密码文件
htpasswd -sc .htpasswd username
```

2. 修改 `docker-compose.yml` 添加认证配置：

```yaml
services:
  pypiserver:
    # ... 其他配置 ...
    volumes:
      - ./packages:/opt/pypi/packages:ro
      - ./.htpasswd:/opt/pypi/.htpasswd:ro
    command: ["pypi-server", "run", "-p", "8080", "-P", "/opt/pypi/.htpasswd", "-a", "update,download", "/opt/pypi/packages"]
```

### 查看可用包列表

**通过浏览器**：
- 访问 `http://localhost:8080/packages/` 查看所有包文件
- 访问 `http://localhost:8080/simple/` 查看包索引

**通过命令行**：

```bash
curl http://localhost:8080/simple/
```

### 查看特定包的版本

```bash
curl http://localhost:8080/simple/numpy/
```

---

## 维护与更新

### 更新 Python 包（推荐方式）

使用磁盘映射方案时，更新包非常简单，**无需重建镜像**：

```bash
# 1. 编辑 requirements.txt 添加/修改包

# 2. 重新运行下载脚本
./download_packages.sh

# 3. 服务会自动识别新包，无需重启容器
```

### 查看容器日志

```bash
# Docker Compose
docker-compose logs -f

# 手动运行的容器
docker logs -f offline-pypi
```

### 查看容器状态

```bash
docker ps | grep offline-pypi
```

### 重启容器

```bash
# Docker Compose
docker-compose restart

# 手动运行的容器
docker restart offline-pypi
```

### 停止服务

```bash
# Docker Compose
docker-compose down

# 手动运行的容器
docker stop offline-pypi
docker rm offline-pypi
```

### 重建镜像

如果需要更新 pypiserver 版本或修改基础配置：

```bash
# 重新构建镜像
docker build -f Dockerfile.pypiserver -t offline-pypi:latest .

# 重启服务
docker-compose down
docker-compose up -d
```

### 备份包文件

```bash
# 直接备份 packages 目录
tar -czf pypi-packages-backup.tar.gz packages/

# 或复制到其他位置
cp -r packages/ /backup/pypi-packages/
```

### 恢复包文件

```bash
# 解压备份
tar -xzf pypi-packages-backup.tar.gz

# 启动服务
docker-compose up -d
```

### 添加私有包

```bash
# 直接将 wheel 文件复制到 packages 目录
cp your-private-package.whl packages/

# pypiserver 会自动识别新包
```

---

## 常见问题

### Q1: 两种方案如何选择？

| 方案 | 适用场景 | 特点 |
|------|----------|------|
| 磁盘映射（推荐） | 包需要经常更新、有外部存储、开发测试环境 | 更新方便，镜像小 |
| 内置镜像 | 无法挂载外部存储、包列表固定、生产环境 | 部署简单，自包含 |

### Q2: 支持哪些操作系统和平台？

**默认支持的平台**：
- ✅ Windows 64位 (win_amd64)
- ✅ Linux x86_64 (manylinux2014_x86_64)

**可选平台**（编辑 `platforms.conf` 启用）：
- Windows 32位 (win32)
- macOS Intel (macosx_10_9_x86_64)
- macOS Apple Silicon (macosx_11_0_arm64)

### Q3: 为什么安装包时提示 "No matching distribution found"？

**原因**：仓库中的包版本与你的 Python 版本或平台不匹配。

**解决方案**：
- 默认支持 Python 3.10，确保客户端版本匹配
- 编辑 `python_versions.conf` 添加需要的 Python 版本
- 重新运行 `./download_packages.sh`
- 某些包可能没有预编译的 wheel（如纯 C 扩展），需要源码编译

### Q4: 如何支持多个 Python 版本？

编辑 `python_versions.conf` 文件，取消需要版本的注释：

```text
# Python 3.10 (默认启用)
310

# 启用 Python 3.11
311

# 启用 Python 3.12
312
```

然后重新运行下载脚本：

```bash
./download_packages.sh
```

### Q5: 下载速度慢怎么办？

- 脚本默认使用阿里云镜像源
- 可以尝试其他镜像源：

```bash
# 清华大学源
./download_packages.sh -m https://pypi.tuna.tsinghua.edu.cn/simple/

# 中科大源
./download_packages.sh -m https://pypi.mirrors.ustc.edu.cn/simple/
```

### Q6: 如何查看已下载的包？

```bash
# 查看包数量和大小
ls -la packages/
du -sh packages/

# 查看特定包
ls packages/ | grep numpy
```

### Q7: 容器占用多少内存？

```bash
docker stats offline-pypi
```

### Q8: 可以在生产环境使用吗？

可以，但建议：
- 启用认证保护
- 配置 HTTPS（通过反向代理）
- 配置自动重启策略
- 定期备份 packages 目录
- 使用只读挂载 (`:ro`)

### Q9: 如何迁移到另一台服务器？

```bash
# 在源服务器上
tar -czf offline-pypi-backup.tar.gz packages/ requirements.txt platforms.conf python_versions.conf

# 复制到目标服务器
scp offline-pypi-backup.tar.gz user@target-server:/path/to/

# 在目标服务器上
tar -xzf offline-pypi-backup.tar.gz
docker-compose up -d
```

---

## 故障排除

### 下载脚本执行失败

**检查依赖**：
```bash
# 确保 pip 可用
pip --version

# 确保脚本有执行权限
chmod +x download_packages.sh
```

**常见错误**：
- 网络问题：检查网络连接或更换镜像源
- 权限问题：使用 `sudo` 或检查目录权限

### 服务无法启动

**检查容器日志**：
```bash
docker-compose logs
# 或
docker logs offline-pypi
```

**常见错误**：
- 端口冲突：更换端口或停止占用 8080 端口的服务
- 挂载失败：确保 packages 目录存在且有读取权限

### 无法连接到服务

**检查容器是否运行**：
```bash
docker ps | grep offline-pypi
```

**检查端口映射**：
```bash
docker port offline-pypi
```

**测试连接**：
```bash
curl http://localhost:8080/
```

### pip 安装失败

**检查 pip 配置**：
```bash
pip config list
```

**清除 pip 缓存**：
```bash
pip cache purge
```

**使用详细输出模式**：
```bash
pip install -vvv --index-url http://localhost:8080/simple/ \
  --trusted-host localhost \
  PACKAGE_NAME
```

### SSL 证书错误

添加 `--trusted-host` 参数：

```bash
pip install --index-url http://localhost:8080/simple/ \
  --trusted-host localhost \
  PACKAGE_NAME
```

或配置 pip：

```bash
pip config set install.trusted-host localhost
```

### 包版本不兼容

查看可用的包版本：

```bash
curl http://localhost:8080/simple/PACKAGE_NAME/
```

指定特定版本安装：

```bash
pip install --index-url http://localhost:8080/simple/ \
  --trusted-host localhost \
  PACKAGE_NAME==1.2.3
```
