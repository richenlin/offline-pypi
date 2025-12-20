#!/bin/bash
#
# Python 包离线下载脚本
# 用于下载指定的 Python 包到本地目录，支持多版本多平台
#
# 使用方法:
#   ./download_packages.sh [选项]
#
# 选项:
#   -r, --requirements FILE   指定 requirements.txt 文件 (默认: ./requirements.txt)
#   -o, --output DIR          指定输出目录 (默认: ./packages)
#   -p, --platforms FILE      指定平台配置文件 (默认: ./platforms.conf)
#   -v, --versions FILE       指定 Python 版本配置文件 (默认: ./python_versions.conf)
#   -m, --mirror URL          指定 PyPI 镜像源 (默认: https://mirrors.aliyun.com/pypi/simple/)
#   -h, --help                显示帮助信息
#

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQUIREMENTS_FILE="${SCRIPT_DIR}/requirements.txt"
PLATFORMS_FILE="${SCRIPT_DIR}/platforms.conf"
PYTHON_VERSIONS_FILE="${SCRIPT_DIR}/python_versions.conf"
PACKAGES_DIR="${SCRIPT_DIR}/packages"
MIRROR_URL="https://mirrors.aliyun.com/pypi/simple/"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    cat << EOF
Python 包离线下载脚本

用法: $0 [选项]

选项:
  -r, --requirements FILE   指定 requirements.txt 文件 (默认: ./requirements.txt)
  -o, --output DIR          指定输出目录 (默认: ./packages)
  -p, --platforms FILE      指定平台配置文件 (默认: ./platforms.conf)
  -v, --versions FILE       指定 Python 版本配置文件 (默认: ./python_versions.conf)
  -m, --mirror URL          指定 PyPI 镜像源 (默认: https://mirrors.aliyun.com/pypi/simple/)
  -h, --help                显示帮助信息

示例:
  $0                                    # 使用默认配置下载
  $0 -o /data/pypi-packages             # 指定输出目录
  $0 -r my-requirements.txt             # 指定依赖文件
  $0 -m https://pypi.org/simple/        # 使用官方 PyPI 源

EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -r|--requirements)
                REQUIREMENTS_FILE="$2"
                shift 2
                ;;
            -o|--output)
                PACKAGES_DIR="$2"
                shift 2
                ;;
            -p|--platforms)
                PLATFORMS_FILE="$2"
                shift 2
                ;;
            -v|--versions)
                PYTHON_VERSIONS_FILE="$2"
                shift 2
                ;;
            -m|--mirror)
                MIRROR_URL="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v pip &> /dev/null; then
        log_error "pip 未安装，请先安装 pip"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
        log_error "Python 未安装，请先安装 Python"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 验证配置文件
validate_config() {
    log_info "验证配置文件..."
    
    if [ ! -f "$REQUIREMENTS_FILE" ]; then
        log_error "requirements 文件不存在: $REQUIREMENTS_FILE"
        exit 1
    fi
    
    if [ ! -f "$PLATFORMS_FILE" ]; then
        log_error "平台配置文件不存在: $PLATFORMS_FILE"
        exit 1
    fi
    
    if [ ! -f "$PYTHON_VERSIONS_FILE" ]; then
        log_error "Python 版本配置文件不存在: $PYTHON_VERSIONS_FILE"
        exit 1
    fi
    
    log_success "配置文件验证通过"
}

# 读取配置文件（跳过注释和空行）
read_config_file() {
    local file="$1"
    local items=()
    
    while IFS= read -r line || [ -n "$line" ]; do
        # 去除前后空白
        line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        # 跳过空行和注释
        if [ -z "$line" ] || [[ "$line" == \#* ]]; then
            continue
        fi
        items+=("$line")
    done < "$file"
    
    echo "${items[@]}"
}

# 读取 Python 版本
read_python_versions() {
    read_config_file "$PYTHON_VERSIONS_FILE"
}

# 读取平台配置
read_platforms() {
    read_config_file "$PLATFORMS_FILE"
}

# 配置 pip 镜像源
configure_pip_mirror() {
    log_info "配置 pip 镜像源: $MIRROR_URL"
    
    # 提取 host 用于 trusted-host
    local host=$(echo "$MIRROR_URL" | sed -E 's|https?://([^/]+).*|\1|')
    
    pip config set global.index-url "$MIRROR_URL" 2>/dev/null || true
    pip config set install.trusted-host "$host" 2>/dev/null || true
}

# 下载当前平台的包（包含所有依赖）
download_current_platform() {
    log_info "下载当前平台包及所有依赖..."
    
    pip download \
        -d "$PACKAGES_DIR" \
        -r "$REQUIREMENTS_FILE" \
        -i "$MIRROR_URL" \
        --trusted-host "$(echo "$MIRROR_URL" | sed -E 's|https?://([^/]+).*|\1|')"
    
    log_success "当前平台包下载完成"
}

# 下载指定版本和平台的包
download_for_platform() {
    local py_version="$1"
    local platform="$2"
    
    log_info "下载: Python ${py_version} + ${platform}"
    
    pip download \
        -d "$PACKAGES_DIR" \
        -r "$REQUIREMENTS_FILE" \
        -i "$MIRROR_URL" \
        --trusted-host "$(echo "$MIRROR_URL" | sed -E 's|https?://([^/]+).*|\1|')" \
        --platform "$platform" \
        --python-version "$py_version" \
        --only-binary=:all: \
        --no-deps 2>/dev/null || log_warn "部分包可能没有 Python ${py_version} + ${platform} 的预编译版本"
}

# 下载多版本多平台包
download_multi_platform() {
    local python_versions=($(read_python_versions))
    local platforms=($(read_platforms))
    
    log_info "目标 Python 版本: ${python_versions[*]}"
    log_info "目标平台: ${platforms[*]}"
    
    for py_version in "${python_versions[@]}"; do
        for platform in "${platforms[@]}"; do
            download_for_platform "$py_version" "$platform"
        done
    done
    
    log_success "多版本多平台包下载完成"
}

# 显示下载统计
show_statistics() {
    echo ""
    echo "=========================================="
    echo "           下载完成统计"
    echo "=========================================="
    echo "包目录: $PACKAGES_DIR"
    
    if [ -d "$PACKAGES_DIR" ]; then
        local pkg_count=$(ls -1 "$PACKAGES_DIR" 2>/dev/null | wc -l | tr -d ' ')
        local total_size=$(du -sh "$PACKAGES_DIR" 2>/dev/null | cut -f1)
        echo "包数量: $pkg_count"
        echo "总大小: $total_size"
    else
        echo "包数量: 0"
    fi
    echo "=========================================="
}

# 主函数
main() {
    echo ""
    echo "=========================================="
    echo "     Python 包离线下载工具"
    echo "=========================================="
    echo ""
    
    # 解析参数
    parse_args "$@"
    
    # 检查依赖
    check_dependencies
    
    # 验证配置
    validate_config
    
    # 显示配置信息
    echo ""
    log_info "配置信息:"
    echo "  - requirements 文件: $REQUIREMENTS_FILE"
    echo "  - 平台配置文件: $PLATFORMS_FILE"
    echo "  - Python 版本配置: $PYTHON_VERSIONS_FILE"
    echo "  - 输出目录: $PACKAGES_DIR"
    echo "  - 镜像源: $MIRROR_URL"
    echo ""
    
    # 创建输出目录
    mkdir -p "$PACKAGES_DIR"
    
    # 配置镜像源
    configure_pip_mirror
    
    echo ""
    echo "=========================================="
    echo ">>> 步骤 1: 下载当前平台包及所有依赖"
    echo "=========================================="
    download_current_platform
    
    echo ""
    echo "=========================================="
    echo ">>> 步骤 2: 下载多版本多平台包"
    echo "=========================================="
    download_multi_platform
    
    # 显示统计
    show_statistics
    
    log_success "所有包下载完成！"
    echo ""
    echo "后续步骤:"
    echo "  1. 启动 pypiserver 服务:"
    echo "     docker-compose up -d"
    echo ""
    echo "  2. 或直接运行容器:"
    echo "     docker run -d -p 8080:8080 -v ${PACKAGES_DIR}:/opt/pypi/packages offline-pypi"
    echo ""
    echo "  3. 配置 pip 使用本地源:"
    echo "     pip install --index-url http://localhost:8080/simple/ <package>"
    echo ""
}

# 运行主函数
main "$@"
