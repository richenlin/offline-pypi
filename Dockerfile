# 使用一个相对精简的 Python 基础镜像
FROM python:3.10-slim

# 设置工作目录
WORKDIR /app

# 配置 pip 使用清华大学镜像源以加速下载
RUN pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/ && \
  pip config set install.trusted-host mirrors.aliyun.com

# 安装必要的系统工具和编译依赖（部分Python包需要）
RUN apt-get update && apt-get install -y --no-install-recommends \
  gcc \
  g++ \
  && rm -rf /var/lib/apt/lists/*

# 安装仓库管理工具
# bandersnatch 支持 toml 配置文件和内置过滤器
# pypiserver 是我们的轻量级仓库服务器
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir bandersnatch pypiserver

# 复制配置文件和包列表到镜像中
COPY requirements.txt .
COPY sync_packages.sh .
COPY bandersnatch.conf .

# 运行同步脚本，确保配置文件中的包列表与 requirements.txt 一致
# 然后将更新后的配置文件复制到 /etc 目录
RUN chmod +x sync_packages.sh && \
    ./sync_packages.sh && \
    cp bandersnatch.conf /etc/bandersnatch.conf

# --- 核心步骤：下载所有 Python 包 ---
# Bandersnatch 会读取 /etc/bandersnatch.conf，找到 requirements_filter 插件，
# 然后读取 /app/requirements.txt，并下载所有指定的包及其依赖到 /opt/pypi
# 这一步会非常耗时，并且会使镜像变得很大
RUN bandersnatch --config /etc/bandersnatch.conf mirror

# 设置 pypiserver 的包根目录
# bandersnatch 会将包下载到 /opt/pypi/web/packages
# pypiserver 需要指向 /opt/pypi/web 目录
ENV PYPI_PACKAGES /opt/pypi/web

# 暴露端口
EXPOSE 8080

# 设置容器启动命令
# 启动 pypiserver，让它服务于我们下载好的包目录
# -a . 表示允许所有动作，-P . 表示无密码认证
CMD ["pypi-server", "run", "-p", "8080", "-a", ".", "/opt/pypi/web/simple"]
