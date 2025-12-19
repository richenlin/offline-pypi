# 离线 Python PyPI 镜像源

这是一个轻量级的离线 Python 包仓库解决方案，适用于无互联网访问或需要本地 PyPI 镜像的环境。

## ✨ 特性

- 🚀 **快速构建**：使用国内镜像源，构建时间 5-10 分钟
- 💡 **轻量级**：镜像大小约 780 MB
- 📦 **易于使用**：标准 pip 安装流程，无需额外配置
- 🔧 **灵活配置**：轻松自定义包列表
- 🐳 **容器化部署**：基于 Docker，一键启动
- 🖥️ **多平台支持**：同时支持 Windows 和 Linux 客户端（可配置）

## 项目概述

本项目提供两种方案：

1. **pip download 方案**（推荐）：使用 `Dockerfile.pip-download`
   - ✅ 快速构建，完全使用国内镜像
   - ✅ 镜像体积小
   - ✅ 适合大多数场景

2. **bandersnatch 方案**：使用 `Dockerfile`
   - 支持增量同步
   - 功能更完整
   - 构建较慢

## 文件说明

- `Dockerfile.pip-download`: 推荐使用的快速构建文件
- `Dockerfile`: 使用 bandersnatch 的完整方案
- `requirements.txt`: 需要镜像的 Python 包列表
- `platforms.conf`: 平台配置文件，定义支持的操作系统
- `python_versions.conf`: Python 版本配置文件，定义支持的 Python 版本
- `bandersnatch.conf`: Bandersnatch 配置文件（仅 Dockerfile 使用）
- `sync_packages.sh`: 自动同步脚本（仅 Dockerfile 使用）
- `USER_GUIDE.md`: 详细使用手册

## 🚀 快速开始

### 1. 构建镜像

```bash
docker build -f Dockerfile.pip-download -t offline-pypi:latest .
```

构建时间约 5-10 分钟。

### 2. 运行容器

```bash
docker run -d -p 8080:8080 --name offline-pypi offline-pypi:latest
```

### 3. 验证服务

访问 http://localhost:8080/ 查看 pypiserver 欢迎页面。

### 4. 使用 pip 安装包

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

## 📝 自定义包列表

编辑 `requirements.txt` 文件，添加您需要的 Python 包：

```txt
# 核心依赖
pip
setuptools
wheel

# 科学计算
numpy
scipy
pandas
matplotlib

# 添加您需要的其他包
your-package-name
```

然后重新构建镜像即可。

## 📦 包含的包

查看 `requirements.txt` 获取完整列表。默认包含：

- **基础工具**: pip, setuptools, wheel
- **科学计算**: numpy, scipy, pandas, matplotlib, scikit-learn
- **数据处理**: h5py, netcdf4, lxml
- **网络请求**: requests
- **图像处理**: opencv-python, pillow

## 🔧 高级功能

### 持久化存储

```bash
docker run -d -p 8080:8080 \
  -v pypi-packages:/opt/pypi/packages \
  --name offline-pypi \
  offline-pypi:latest
```

### 远程访问

```bash
docker run -d -p 0.0.0.0:8080:8080 --name offline-pypi offline-pypi:latest
```

**Linux/macOS 客户端**：
```bash
pip install --index-url http://192.168.1.100:8080/simple/ \
  --trusted-host 192.168.1.100 \
  numpy
```

**Windows 客户端**：
```cmd
pip install --index-url http://192.168.1.100:8080/simple/ --trusted-host 192.168.1.100 numpy
```

### 自动重启

```bash
docker run -d -p 8080:8080 \
  --restart unless-stopped \
  --name offline-pypi \
  offline-pypi:latest
```

## 📚 详细文档

更多详细信息，请查看 **[USER_GUIDE.md](USER_GUIDE.md)**，包括：

- 完整的使用说明
- 高级配置选项
- 故障排除指南
- 常见问题解答
- Python 多版本支持
- 认证配置
- 备份与恢复

## 💡 常见问题

**Q: 支持哪些操作系统？**  
A: 默认支持 Windows 64位和 Linux。可通过编辑 `platforms.conf` 文件添加更多平台（如 Windows 32位、macOS 等）。

**Q: 为什么安装包时提示 "No matching distribution found"？**  
A: 可能原因：
1. 默认支持 Python 3.10，请确保客户端版本匹配
2. 某些包可能没有预编译的 wheel 文件（纯源码包）
3. 如需支持其他 Python 版本，编辑 `python_versions.conf` 文件

**Q: 如何支持多个 Python 版本？**  
A: 编辑 `python_versions.conf` 文件，取消需要版本的注释，然后重新构建镜像。

**Q: 容器管理命令？**
```bash
docker logs offline-pypi        # 查看日志
docker stop offline-pypi        # 停止
docker start offline-pypi       # 启动
docker restart offline-pypi     # 重启
docker rm offline-pypi          # 删除
```

## 📊 技术栈

- **基础镜像**: Python 3.10-slim
- **包管理**: pypiserver 2.4.0
- **镜像大小**: ~780 MB
- **包存储**: ~183 MB（取决于 requirements.txt）
- **默认端口**: 8080

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

---

**更新日期**: 2025-10-02  
**版本**: 1.0.0

