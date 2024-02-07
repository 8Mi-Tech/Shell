#!/bin/bash

# 检测系统发行版类型并安装相应的前置包

# 检测系统发行版
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ -n "$ID" ]; then
            echo "$ID"
            return
        fi
    elif [ -f /etc/redhat-release ]; then
        echo "Red Hat"
        return
    elif [ -f /etc/debian_version ]; then
        echo "Debian"
        return
    fi

    echo "Unknown"
}

# 安装前置包
install_dependencies() {
    distro="$1"
    case "$distro" in
        "ubuntu" | "debian")
            sudo apt update
            sudo apt install -y rclone fuse3
            ;;
        "fedora" | "centos" | "rhel")
            sudo yum update
            sudo yum install -y rclone fuse3
            ;;
        "arch" | "manjaro")
            sudo pacman -Syu
            sudo pacman -S --noconfirm rclone fuse3
            ;;
        *)
            echo "不支持的发行版类型: $distro"
            exit 1
            ;;
    esac
}

# 主程序
main() {
    distro=$(detect_linux_distro)
    echo "检测到的发行版类型: $distro"
    install_dependencies "$distro"
    echo "前置包安装完成."
}

# 执行主程序
main
