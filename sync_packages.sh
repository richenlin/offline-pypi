#!/bin/bash

# 同步 requirements.txt 到 bandersnatch.conf
# 用途：读取 requirements.txt 中的包名，自动更新 bandersnatch.conf 的白名单

set -e

REQUIREMENTS_FILE="requirements.txt"
BANDERSNATCH_CONF="bandersnatch.conf"

# 检查文件是否存在
if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo "错误: 找不到 $REQUIREMENTS_FILE 文件"
    exit 1
fi

if [ ! -f "$BANDERSNATCH_CONF" ]; then
    echo "错误: 找不到 $BANDERSNATCH_CONF 文件"
    exit 1
fi

echo "正在从 $REQUIREMENTS_FILE 读取包列表..."

# 读取 requirements.txt，过滤掉注释、空行和版本号
# 提取纯包名（去除 ==, >=, <=, ~= 等版本约束）
PACKAGES=$(grep -v '^#' "$REQUIREMENTS_FILE" | \
           grep -v '^[[:space:]]*$' | \
           sed 's/[><=~!].*//' | \
           sed 's/\[.*\]//' | \
           sed 's/[[:space:]]*$//' | \
           sort -u)

if [ -z "$PACKAGES" ]; then
    echo "警告: 没有找到任何包"
    exit 1
fi

echo "找到以下包:"
echo "$PACKAGES"
echo ""

# 创建临时文件
TEMP_CONF=$(mktemp)

# 读取配置文件并替换 [allowlist] 部分
IN_ALLOWLIST=false
ALLOWLIST_WRITTEN=false

while IFS= read -r line; do
    # 检测到 [allowlist] 部分开始
    if [[ "$line" =~ ^\[allowlist\] ]]; then
        IN_ALLOWLIST=true
        echo "$line" >> "$TEMP_CONF"
        continue
    fi
    
    # 检测到新的配置段，allowlist 部分结束
    if [[ "$line" =~ ^\[.*\] ]] && [ "$IN_ALLOWLIST" = true ]; then
        # 在新段之前写入包列表
        if [ "$ALLOWLIST_WRITTEN" = false ]; then
            echo "packages =" >> "$TEMP_CONF"
            while IFS= read -r pkg; do
                echo "    $pkg" >> "$TEMP_CONF"
            done <<< "$PACKAGES"
            ALLOWLIST_WRITTEN=true
            echo "" >> "$TEMP_CONF"
        fi
        IN_ALLOWLIST=false
    fi
    
    # 如果在 allowlist 部分且行以 packages 开头，跳过旧的包列表
    if [ "$IN_ALLOWLIST" = true ] && [[ "$line" =~ ^packages[[:space:]]*= ]]; then
        echo "packages =" >> "$TEMP_CONF"
        while IFS= read -r pkg; do
            echo "    $pkg" >> "$TEMP_CONF"
        done <<< "$PACKAGES"
        ALLOWLIST_WRITTEN=true
        
        # 跳过后续的包列表行（以空格开头）
        while IFS= read -r next_line; do
            if [[ "$next_line" =~ ^[[:space:]]+[a-zA-Z0-9_-]+ ]]; then
                continue
            else
                echo "$next_line" >> "$TEMP_CONF"
                break
            fi
        done
        continue
    fi
    
    # 如果在 allowlist 且是包列表项（以空格开头），跳过
    if [ "$IN_ALLOWLIST" = true ] && [[ "$line" =~ ^[[:space:]]+[a-zA-Z0-9_-]+ ]]; then
        continue
    fi
    
    # 其他行直接写入
    echo "$line" >> "$TEMP_CONF"
    
done < "$BANDERSNATCH_CONF"

# 如果到文件末尾还在 allowlist 部分，需要写入包列表
if [ "$IN_ALLOWLIST" = true ] && [ "$ALLOWLIST_WRITTEN" = false ]; then
    echo "packages =" >> "$TEMP_CONF"
    while IFS= read -r pkg; do
        echo "    $pkg" >> "$TEMP_CONF"
    done <<< "$PACKAGES"
fi

# 备份原配置文件
cp "$BANDERSNATCH_CONF" "${BANDERSNATCH_CONF}.backup"
echo "已备份原配置文件到 ${BANDERSNATCH_CONF}.backup"

# 替换配置文件
mv "$TEMP_CONF" "$BANDERSNATCH_CONF"

echo ""
echo "✓ 成功更新 $BANDERSNATCH_CONF"
echo ""
echo "包列表已同步，共 $(echo "$PACKAGES" | wc -l) 个包"

