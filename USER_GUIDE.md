# 离线 Python 仓库使用手册

## 📖 目录

- [简介](#简介)
- [快速开始](#快速开始)
- [构建镜像](#构建镜像)
- [运行容器](#运行容器)
- [使用 pip 安装包](#使用-pip-安装包)
- [高级配置](#高级配置)
- [维护与更新](#维护与更新)
- [常见问题](#常见问题)
- [故障排除](#故障排除)

---

## 简介

这是一个轻量级的离线 Python 包仓库解决方案，基于 `pypiserver` 构建。它可以让你在无网络或网络受限的环境中安装 Python 包。

### 特性

- ✅ 轻量级，镜像大小约 780 MB
- ✅ 使用国内镜像源加速构建
- ✅ 支持标准的 pip 安装流程
- ✅ 包含常用的科学计算和数据处理库
- ✅ 无需认证，易于部署
- ✅ 多平台支持：Windows、Linux（可通过配置文件扩展）

### 系统要求

- Docker 20.10 或更高版本
- 至少 1 GB 可用磁盘空间
- （构建时）网络连接以下载包

---

## 快速开始

### 1. 克隆或下载项目

```bash
git clone <repository-url>
cd offline-pypi
```

### 2. 构建镜像

```bash
docker build -f Dockerfile.pip-download -t offline-pypi:latest .
```

构建时间约 5-10 分钟，取决于网络速度。

### 3. 运行容器

```bash
docker run -d -p 8080:8080 --name offline-pypi offline-pypi:latest
```

### 4. 验证服务

在浏览器中访问 `http://localhost:8080/`，应该能看到 pypiserver 的欢迎页面。

### 5. 测试安装

```bash
pip install --index-url http://localhost:8080/simple/ --trusted-host localhost numpy
```

---

## 构建镜像

### 标准构建

使用 `Dockerfile.pip-download`（推荐）：

```bash
docker build -f Dockerfile.pip-download -t offline-pypi:latest .
```

**优点**：
- 使用国内镜像源，下载速度快
- 构建时间短
- 镜像体积小

### 自定义包列表

编辑 `requirements.txt` 文件，添加或删除需要的包：

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
```

然后重新构建镜像。

### 自定义平台支持

编辑 `platforms.conf` 文件，配置需要支持的操作系统平台：

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

修改后重新构建镜像即可。

### 自定义 Python 版本支持

编辑 `python_versions.conf` 文件，配置需要支持的 Python 版本：

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

修改后重新构建镜像即可。

> **注意**：启用多个版本会增加镜像大小和构建时间。

### 构建参数

你可以使用 Docker 构建参数来自定义镜像：

```bash
# 使用不同的 Python 版本
docker build -f Dockerfile.pip-download \
  --build-arg PYTHON_VERSION=3.11 \
  -t offline-pypi:py311 .
```

---

## 运行容器

### 基本运行

```bash
docker run -d -p 8080:8080 --name offline-pypi offline-pypi:latest
```

### 使用自定义端口

```bash
docker run -d -p 9000:8080 --name offline-pypi offline-pypi:latest
```

然后通过 `http://localhost:9000/` 访问。

### 持久化存储（推荐）

如果需要在容器重启后保留数据：

```bash
docker run -d -p 8080:8080 \
  -v pypi-packages:/opt/pypi/packages \
  --name offline-pypi \
  offline-pypi:latest
```

### 后台运行与自动重启

```bash
docker run -d \
  -p 8080:8080 \
  --name offline-pypi \
  --restart unless-stopped \
  offline-pypi:latest
```

### 资源限制

```bash
docker run -d -p 8080:8080 \
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
  --name offline-pypi \
  offline-pypi:latest
```

然后在客户端使用服务器 IP：

```bash
pip install --index-url http://192.168.1.100:8080/simple/ \
  --trusted-host 192.168.1.100 \
  numpy
```

### 启用认证

修改 `Dockerfile.pip-download` 的 CMD 行：

```dockerfile
CMD ["pypi-server", "run", "-p", "8080", \
     "-P", "/path/to/.htpasswd", \
     "-a", "update,download", \
     "/opt/pypi/packages"]
```

创建密码文件：

```bash
htpasswd -sc .htpasswd username
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

### 查看容器日志

```bash
docker logs offline-pypi
```

实时查看日志：

```bash
docker logs -f offline-pypi
```

### 查看容器状态

```bash
docker ps | grep offline-pypi
```

### 重启容器

```bash
docker restart offline-pypi
```

### 停止容器

```bash
docker stop offline-pypi
```

### 删除容器

```bash
docker stop offline-pypi
docker rm offline-pypi
```

### 更新包列表

1. 修改 `requirements.txt`
2. 重新构建镜像：

```bash
docker build -f Dockerfile.pip-download -t offline-pypi:latest .
```

3. 停止并删除旧容器：

```bash
docker stop offline-pypi
docker rm offline-pypi
```

4. 运行新容器：

```bash
docker run -d -p 8080:8080 --name offline-pypi offline-pypi:latest
```

### 备份包文件

```bash
# 从容器中复制包文件
docker cp offline-pypi:/opt/pypi/packages ./backup/

# 或使用 volume 备份
docker run --rm \
  -v pypi-packages:/data \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/pypi-packages.tar.gz -C /data .
```

### 恢复包文件

```bash
docker run -d -p 8080:8080 \
  -v $(pwd)/backup/packages:/opt/pypi/packages \
  --name offline-pypi \
  offline-pypi:latest
```

---

## 常见问题

### Q1: 支持哪些操作系统和平台？

**默认支持的平台**：
- ✅ Windows 64位 (win_amd64)
- ✅ Linux x86_64 (manylinux2014_x86_64)

**可选平台**（编辑 `platforms.conf` 启用）：
- Windows 32位 (win32)
- macOS Intel (macosx_10_9_x86_64)
- macOS Apple Silicon (macosx_11_0_arm64)

通过编辑 `platforms.conf` 文件可以自定义支持的平台。

### Q2: 为什么安装包时提示 "No matching distribution found"？

**原因**：仓库中的包版本与你的 Python 版本或平台不匹配。

**解决方案**：
- 镜像使用 Python 3.10 构建，只包含 cp310 的 wheel 文件
- 确保你的环境也使用 Python 3.10
- 某些包可能没有预编译的 wheel（如纯 C 扩展），需要源码编译
- 或者重新构建镜像时使用你需要的 Python 版本

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

然后重新构建镜像：

```bash
docker build -f Dockerfile.pip-download -t offline-pypi:latest .
```

构建时会自动为每个 Python 版本 + 平台组合下载包。

### Q5: 构建镜像时下载速度慢怎么办？

- 确保 `Dockerfile.pip-download` 中配置了国内镜像源（阿里云/清华）
- 检查网络连接
- 尝试在网络较好的时段构建

### Q6: 如何查看镜像大小？

```bash
docker images offline-pypi
```

### Q7: 容器占用多少内存？

```bash
docker stats offline-pypi
```

### Q8: 可以在生产环境使用吗？

可以，但建议：
- 启用认证保护
- 配置 HTTPS
- 使用 volume 持久化数据
- 配置自动重启策略
- 定期备份

### Q9: 如何添加自己的私有包？

```bash
# 将本地 wheel 文件复制到容器
docker cp your-package.whl offline-pypi:/opt/pypi/packages/

# 或在构建时添加
COPY ./local-packages/*.whl /opt/pypi/packages/
```

---

## 故障排除

### 服务无法启动

**检查容器日志**：
```bash
docker logs offline-pypi
```

**常见错误**：
- 端口冲突：更换端口或停止占用 8080 端口的服务
- 权限问题：使用 `docker run` 时添加 `--user` 参数

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

---

## 附录

### A. 镜像信息

- **基础镜像**: `python:3.10-slim`
- **镜像大小**: ~780 MB
- **包存储**: ~183 MB
- **默认端口**: 8080
- **包管理工具**: pypiserver 2.4.0

### B. 包含的包列表

查看 `requirements.txt` 文件获取完整列表。核心包包括：

- **基础工具**: pip, setuptools, wheel
- **科学计算**: numpy, scipy, pandas, matplotlib, scikit-learn
- **数据处理**: h5py, netcdf4, lxml
- **网络请求**: requests
- **图像处理**: opencv-python, pillow

### C. 相关链接

- [pypiserver 官方文档](https://pypi.org/project/pypiserver/)
- [pip 官方文档](https://pip.pypa.io/)
- [Docker 官方文档](https://docs.docker.com/)

### D. 技术支持

如遇到问题，请提供以下信息：

1. Docker 版本：`docker --version`
2. Python 版本：`python --version`
3. 操作系统信息
4. 容器日志：`docker logs offline-pypi`
5. 错误信息截图

---

## 许可证

本项目采用 MIT 许可证。

---

**更新日期**: 2025-10-02
**版本**: 1.0.0

