#!/bin/bash

# Go语言安装脚本（系统级安装版）
# 支持版本：1.15.15 至 1.24.3
# 自动检测系统架构并立即生效环境变量
# 支持交互式安装和卸载
# 支持阿里云镜像下载
# 版本：2.0
# 作者：Socks
# 日期：2025-05-30
# 祝您使用愉快！

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
)

# 显示帮助信息
show_help() {
    echo "Go语言安装脚本 (系统级安装)"
    echo "支持版本: 1.15.15 至 1.24.3"
    echo "安装位置: /usr/local/go"
    echo
    echo "使用方法:"
    echo "  $0 [选项]"
    echo
    echo "选项:"
    echo "  -v, --version 版本号   安装指定版本"
    echo "  -l, --list            列出可用版本"
    echo "  -u, --uninstall       卸载Go语言"
    echo "  -c, --custom          安装自定义版本"
    echo "  -m, --mirror          使用阿里云镜像下载"
    echo "  -h, --help            显示帮助信息"
    echo
    echo "示例:"
    echo "  $0                     # 交互式安装"
    echo "  $0 -v 1.20.17         # 安装指定版本"
    echo "  $0 -c 1.24.4          # 安装自定义版本"
    echo "  $0 -u                 # 卸载Go语言"
    echo "  $0 -m -v 1.20.17      # 使用镜像下载安装"
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

# 安装Go
install_go() {
    local version=$1
    local arch=$2
    local use_mirror=$3
    
    # 安装目录
    local install_dir="/usr/local"
    local go_root="$install_dir/go"
    
    echo "正在安装 Go ${version} (${arch})..."
    echo "安装位置: $install_dir"
    
    # 清理旧安装
    sudo rm -rf "$go_root" 2>/dev/null || true
    
    # 创建临时目录
    local tmp_dir
    tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || exit 1
    
    # 设置下载URL
    local filename="go${version}.linux-${arch}.tar.gz"
    local mirror_url="https://mirrors.aliyun.com/golang"
    local official_url="https://dl.google.com/go"
    
    # 根据用户选择设置下载源
    local download_url
    if [[ "$use_mirror" == true ]]; then
        echo "使用阿里云镜像下载"
        download_url="${mirror_url}/${filename}"
    else
        echo "使用官方源下载"
        download_url="${official_url}/${filename}"
    fi
    
    echo "正在下载 ${filename}..."
    echo "下载地址: $download_url"
    
    # 尝试下载
    if ! curl -fOL --progress-bar "$download_url"; then
        echo "下载失败，尝试备用源..."
        
        # 切换源重试
        if [[ "$use_mirror" == true ]]; then
            download_url="${official_url}/${filename}"
        else
            download_url="${mirror_url}/${filename}"
        fi
        
        echo "尝试备用源: $download_url"
        if ! curl -fOL --progress-bar "$download_url"; then
            echo "错误: 无法下载 Go ${version} (${arch})"
            echo "请检查版本号和架构是否可用"
            exit 1
        fi
    fi
    
    echo "正在解压安装..."
    # 验证文件完整性
    if ! tar -tzf "$filename" &>/dev/null; then
        echo "下载的文件已损坏，请重试"
        exit 1
    fi
    
    # 解压安装
    sudo tar -C "$install_dir" -xzf "$filename"
    
    # 清理安装包
    rm -f "$filename"
    
    # 设置环境变量
    setup_environment
}

# 配置环境变量
setup_environment() {
    local profile_file="/etc/profile.d/go.sh"
    
    echo "配置环境变量..."
    
    # 创建配置文件
    sudo tee "$profile_file" >/dev/null <<EOF
#!/bin/sh
export PATH="\$PATH:/usr/local/go/bin"
export GOROOT="/usr/local/go"
EOF
    
    # 设置权限
    sudo chmod 755 "$profile_file"
    
    # 添加到当前用户bashrc（可选）
    if [[ -f "$HOME/.bashrc" ]]; then
        if ! grep -q "source $profile_file" "$HOME/.bashrc"; then
            echo -e "\n# Go环境配置\nsource $profile_file" | sudo tee -a "$HOME/.bashrc" >/dev/null
        fi
    fi
    
    # 添加到当前用户zshrc（可选）
    if [[ -f "$HOME/.zshrc" ]]; then
        if ! grep -q "source $profile_file" "$HOME/.zshrc"; then
            echo -e "\n# Go环境配置\nsource $profile_file" | sudo tee -a "$HOME/.zshrc" >/dev/null
        fi
    fi
    
    # 当前Shell立即生效
    source "$profile_file" 2>/dev/null || true
    
    echo "环境配置完成: ${profile_file}"
}

# 交互式主菜单
interactive_main_menu() {
    while true; do
        echo
        echo "=============================================="
        echo "            Go语言版本管理向导2.0"
        echo "=============================================="
        echo
        echo "主菜单:"
        echo " 1) 安装Go语言"
        echo " 2) 卸载Go语言"
        echo " 3) 显示帮助信息"
        echo " 0) 退出"
        echo
        
        # 获取用户选择
        read -rp "请选择操作 [0-3]: " choice
        
        case $choice in
            1)
                interactive_install_menu
                ;;
            2)
                uninstall_go
                ;;
            3)
                show_help
                ;;
            0)
                echo "已退出"
                exit 0
                ;;
            *)
                echo "无效选择，请输入 0 到 3 之间的数字"
                ;;
        esac
    done
}

# 交互式安装菜单
interactive_install_menu() {
    echo
    echo "=============================================="
    echo "            Go语言版本安装"
    echo "=============================================="
    echo
    echo "可用版本:"
    
    # 显示版本列表
    for i in "${!AVAILABLE_VERSIONS[@]}"; do
        printf "%-2d) Go %s\n" $((i+1)) "${AVAILABLE_VERSIONS[$i]}"
    done
    printf "%-2d) %s\n" $(( ${#AVAILABLE_VERSIONS[@]} + 1 )) "自定义版本"
    
    echo " 0) 返回主菜单"
    echo
    
    # 获取用户选择
    while true; do
        read -rp "请选择要安装的版本编号 [0-$(( ${#AVAILABLE_VERSIONS[@]} + 1 ))]: " choice
        
        # 检查输入是否有效
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            if (( choice == 0 )); then
                return
            elif (( choice >= 1 && choice <= ${#AVAILABLE_VERSIONS[@]} )); then
                SELECTED_VERSION=${AVAILABLE_VERSIONS[$((choice-1))]}
                break
            elif (( choice == $(( ${#AVAILABLE_VERSIONS[@]} + 1 )) )); then
                read -rp "请输入要安装的Go版本号: " custom_version
                SELECTED_VERSION="$custom_version"
                break
            else
                echo "无效选择，请输入 0 到 $(( ${#AVAILABLE_VERSIONS[@]} + 1 )) 之间的数字"
            fi
        else
            echo "请输入有效的数字"
        fi
    done
    
    # 检测架构
    local arch
    arch=$(detect_arch)
    if [[ "$arch" == "unsupported" ]]; then
        echo "不支持的系统架构: $(uname -m)"
        return
    fi
    
    # 询问是否使用镜像
    local use_mirror=false
    read -rp "是否使用阿里云镜像下载? [Y/n] " mirror_choice
    if [[ "$mirror_choice" =~ ^[Nn] ]]; then
        use_mirror=false
    else
        use_mirror=true
    fi
    
    # 确认安装
    echo
    read -rp "即将安装 Go ${SELECTED_VERSION} (${arch})，是否继续? [Y/n] " confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        echo "安装已取消"
        return
    fi
    
    # 执行安装
    install_go "$SELECTED_VERSION" "$arch" "$use_mirror"
    
    # 验证安装
    echo
    if command -v go &>/dev/null && go version &>/dev/null; then
        echo "Go ${SELECTED_VERSION} 安装成功！"
        go version
        echo
        echo "环境变量已自动生效，请重新连接终端！"
    else
        echo "安装验证失败！"
    fi
    
    read -rp "按回车键返回主菜单..."
}

# 卸载Go
uninstall_go() {
    echo
    echo "=============================================="
    echo "            Go语言卸载"
    echo "=============================================="
    echo
    
    # 确认卸载
    if ! command -v go &> /dev/null; then
        echo "系统未检测到Go语言安装"
        read -rp "按回车键返回主菜单..."
        return
    fi
    
    current_version=$(go version | awk '{print $3}' | sed 's/go//')
    read -rp "确定要卸载Go语言 (当前版本: ${current_version})? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy] ]]; then
        echo "卸载已取消"
        read -rp "按回车键返回主菜单..."
        return
    fi
    
    echo "开始卸载Go语言..."
    
    # 1. 删除安装目录
    echo "删除Go安装目录..."
    sudo rm -rf "/usr/local/go" 2>/dev/null || true
    
    # 2. 删除环境配置文件
    echo "删除环境配置文件..."
    sudo rm -f "/etc/profile.d/go.sh" 2>/dev/null || true
    
    # 3. 清理用户配置文件
    echo "清理用户配置文件..."
    
    # 清理.bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        sudo sed -i '/source \/etc\/profile.d\/go.sh/d' "$HOME/.bashrc"
        sudo sed -i '/# Go环境配置/d' "$HOME/.bashrc"
    fi
    
    # 清理.zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        sudo sed -i '/source \/etc\/profile.d\/go.sh/d' "$HOME/.zshrc"
        sudo sed -i '/# Go环境配置/d' "$HOME/.zshrc"
    fi
    
    # 4. 刷新环境变量
    echo "刷新环境变量..."
    hash -r 2>/dev/null || true
    
    # 5. 清理缓存和临时文件
    echo "清理缓存文件..."
    sudo rm -rf /tmp/go-build* 2>/dev/null || true
    
    # 6. 检测是否卸载成功
    echo
    if ! command -v go &> /dev/null; then
        echo "Go语言已成功卸载！"
        echo "建议重新打开终端以使环境变更完全生效"
    else
        echo "卸载完成，但检测到go命令仍然存在，请手动检查环境"
    fi
    
    read -rp "按回车键返回主菜单..."
}

# 主安装流程（非交互式）
main_install() {
    local selected_version=$1
    local use_mirror=$2
    
    # 检测架构
    local arch
    arch=$(detect_arch)
    if [[ "$arch" == "unsupported" ]]; then
        echo "不支持的系统架构: $(uname -m)"
        exit 1
    fi
    
    # 执行安装
    install_go "$selected_version" "$arch" "$use_mirror"
    
    # 验证安装
    echo
    if command -v go &>/dev/null && go version &>/dev/null; then
        echo "Go ${selected_version} 安装成功！"
        go version
        echo
        echo "环境变量已自动生效，请重新连接终端！"
    else
        echo "安装验证失败！"
        exit 1
    fi
}

# 参数处理
USE_MIRROR=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            TARGET_VERSION=$2
            shift 2
            ;;
        -c|--custom)
            TARGET_VERSION=$2
            CUSTOM_MODE=true
            shift 2
            ;;
        -l|--list)
            echo "可用版本:"
            printf "Go %s\n" "${AVAILABLE_VERSIONS[@]}"
            exit 0
            ;;
        -u|--uninstall)
            UNINSTALL_MODE=true
            shift
            ;;
        -m|--mirror)
            USE_MIRROR=true
            shift
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

# 处理卸载请求
if [[ "$UNINSTALL_MODE" == true ]]; then
    uninstall_go
    exit 0
fi

# 如果指定了版本，则直接安装
if [[ -n "$TARGET_VERSION" ]]; then
    main_install "$TARGET_VERSION" "$USE_MIRROR"
    exit 0
fi

# 启动交互式主菜单
interactive_main_menu
