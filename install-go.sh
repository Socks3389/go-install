#!/bin/bash

# Go语言安装脚本（交互式增强版）
# 支持版本：1.15.0 至 1.24.3
# 自动检测系统架构并立即生效环境变量

set -e

# 可安装版本列表（按版本号倒序排列）
AVAILABLE_VERSIONS=(
    "1.24.3"
    "1.23.8"
    "1.22.11"
    "1.21.12"
    "1.20.17"
    "1.19.13"
    "1.18.10"
    "1.17.13"
    "1.16.15"
    "1.15.15"
    "1.15.0"
)

# 显示帮助信息
show_help() {
    echo "Go语言安装脚本 (交互式)"
    echo "支持版本: 1.15.0 至 1.24.3"
    echo
    echo "使用方法:"
    echo "  $0 [选项]"
    echo
    echo "选项:"
    echo "  -v, --version 版本号   安装指定版本"
    echo "  -l, --list            列出可用版本"
    echo "  -h, --help            显示帮助信息"
    echo
    echo "示例:"
    echo "  $0                     # 交互式安装"
    echo "  $0 -v 1.20.17         # 安装指定版本"
    echo
}

# 检测系统架构
detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)  echo "amd64" ;;
        aarch64) echo "arm64" ;;
        armv7l)  echo "armv6l" ;;
        *)       echo "unsupported"; return 1 ;;
    esac
}

# 验证版本号有效性
validate_version() {
    local version=$1
    for v in "${AVAILABLE_VERSIONS[@]}"; do
        [[ "$v" == "$version" ]] && return 0
    done
    return 1
}

# 安装Go
install_go() {
    local version=$1
    local arch=$2
    
    echo "正在安装 Go ${version} (${arch})..."
    
    # 清理旧安装
    sudo rm -rf /usr/local/go 2>/dev/null || true
    
    # 创建临时目录
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || exit 1
    
    # 设置下载URL
    local filename="go${version}.linux-${arch}.tar.gz"
    local mirror_url="https://mirrors.aliyun.com/golang"
    local official_url="https://dl.google.com/go"
    
    echo "正在下载 ${filename}..."
    # 尝试下载
    if ! curl -fOL --progress-bar "${mirror_url}/${filename}" 2>/dev/null; then
        echo "镜像下载失败，尝试官方源..."
        curl -fOL --progress-bar "${official_url}/${filename}"
    fi
    
    echo "正在解压安装..."
    # 解压安装
    sudo tar -C /usr/local -xzf "$filename"
    
    # 清理
    cd - >/dev/null || exit 1
    rm -rf "$tmp_dir"
}

# 配置环境变量
setup_environment() {
    local profile_file="/etc/profile.d/go.sh"
    
    echo "配置环境变量..."
    
    # 创建配置文件
    sudo tee "$profile_file" >/dev/null <<EOF
#!/bin/sh
export PATH=\$PATH:/usr/local/go/bin
export GOROOT=/usr/local/go
EOF
    
    # 设置权限
    sudo chmod 755 "$profile_file"
    
    # 当前Shell立即生效
    source "$profile_file"
    
    # 添加到当前用户bashrc（可选）
    if [[ -f "$HOME/.bashrc" ]]; then
        if ! grep -q "source $profile_file" "$HOME/.bashrc"; then
            echo -e "\n# Go环境配置\nsource $profile_file" >> "$HOME/.bashrc"
        fi
    fi
    
    echo "环境配置完成: ${profile_file}"
}

# 交互式安装菜单
interactive_menu() {
    echo
    echo "=============================================="
    echo "            Go语言版本安装向导"
    echo "=============================================="
    echo
    echo "可用版本:"
    
    # 显示版本列表
    for i in "${!AVAILABLE_VERSIONS[@]}"; do
        printf "%-2d) Go %s\n" $((i+1)) "${AVAILABLE_VERSIONS[$i]}"
    done
    
    echo " 0) 退出安装"
    echo
    
    # 获取用户选择
    while true; do
        read -rp "请选择要安装的版本编号 [1-${#AVAILABLE_VERSIONS[@]}]: " choice
        
        # 检查输入是否有效
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            if (( choice == 0 )); then
                echo "安装已取消"
                exit 0
            elif (( choice >= 1 && choice <= ${#AVAILABLE_VERSIONS[@]} )); then
                SELECTED_VERSION=${AVAILABLE_VERSIONS[$((choice-1))]}
                return
            fi
        fi
        
        echo "无效选择，请输入 1 到 ${#AVAILABLE_VERSIONS[@]} 之间的数字"
    done
}

# 主安装流程
main_install() {
    local selected_version=$1
    
    # 检测架构
    local arch
    arch=$(detect_arch)
    if [[ "$arch" == "unsupported" ]]; then
        echo "不支持的系统架构: $(uname -m)"
        exit 1
    fi
    
    # 交互式版本选择
    if [[ -z "$selected_version" ]]; then
        interactive_menu
    else
        # 验证版本
        if ! validate_version "$selected_version"; then
            echo "无效版本: $selected_version"
            exit 1
        fi
        SELECTED_VERSION=$selected_version
    fi
    
    # 确认安装
    echo
    read -rp "即将安装 Go ${SELECTED_VERSION} (${arch})，是否继续? [Y/n] " confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        echo "安装已取消"
        exit 0
    fi
    
    # 执行安装
    install_go "$SELECTED_VERSION" "$arch"
    setup_environment
    
    # 验证安装
    echo
    if /usr/local/go/bin/go version &>/dev/null; then
        echo "Go ${SELECTED_VERSION} 安装成功！"
        /usr/local/go/bin/go version
        echo
        echo "环境变量已自动生效，请重新连接终端！"
    else
        echo "安装验证失败！"
        exit 1
    fi
}

# 参数处理
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            TARGET_VERSION=$2
            shift 2
            ;;
        -l|--list)
            echo "可用版本:"
            printf "Go %s\n" "${AVAILABLE_VERSIONS[@]}"
            exit 0
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查root权限
if [[ $EUID -ne 0 ]]; then
   echo "此脚本需要 root 权限执行" 
   exit 1
fi

# 启动安装
main_install "$TARGET_VERSION"
