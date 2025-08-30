#!/bin/bash

# 检查必要的工具是否安装
check_dependencies() {
    local dependencies=("curl" "jq" "base64" "zbarimg" "qrencode")
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "错误: 未找到 $cmd 命令，请先安装"
            case "$cmd" in
                "jq")
                    echo "在Ubuntu/Debian上使用: sudo apt install jq"
                    ;;
                "zbarimg")
                    echo "在Ubuntu/Debian上使用: sudo apt install zbar-tools"
                    ;;
                "qrencode")
                    echo "在Ubuntu/Debian上使用: sudo apt install qrencode"
                    ;;
                *)
                    echo "请安装 $cmd"
                    ;;
            esac
            exit 1
        fi
    done
}

# 生成二维码并获取UUID
generate_qrcode() {
    local url="https://panservice.mail.wo.cn/wohome/open/v1/QRCode/generate"
    echo "正在生成二维码..."
    
    # 发送GET请求，添加Origin头部
    local response
    response=$(curl -s -H 'X-YP-Client-Id: 1001000021' "$url")
    
    # 检查请求是否成功
    local code
    code=$(echo "$response" | jq -r '.meta.code')
    if [ "$code" != "200" ]; then
        echo "二维码生成失败: $(echo "$response" | jq -r '.meta.message')"
        exit 1
    fi
    
    # 提取base64图像数据和UUID
    local image_base64
    image_base64=$(echo "$response" | jq -r '.result.image')
    uuid=$(echo "$response" | jq -r '.result.uuid')
    
    # 解码base64为图片文件

    
    # 使用zbarimg解码二维码内容
    qr_content=$(echo "$image_base64" | base64 -d | zbarimg -q --raw qrcode.png)
    
    if [ -z "$qr_content" ]; then
        echo "二维码解码失败"
        exit 1
    fi
    
    #echo "解码出的二维码内容: $qr_content"
    
    # 生成终端可显示的二维码
    echo "终端二维码:"
    qrencode -t ANSI "$qr_content"
}

# 查询二维码状态
query_qrcode_status() {
    local uuid=$1
    local query_url="https://panservice.mail.wo.cn/wohome/open/v1/QRCode/query?uuid=$uuid"
    local prev_state=""

    while true; do
        # 发送GET请求，添加Origin头部
        local response=$(curl -s -H 'X-YP-Client-Id: 1001000021' "$query_url")
        
        local code=$(echo "$response" | jq -r '.meta.code')
        if [ "$code" != "200" ]; then
            echo "状态查询失败: $(echo "$response" | jq -r '.meta.message')"
            sleep 1
            continue
        fi
        
        local state=$(echo "$response" | jq -r '.result.state')
        if [ "$state" != "$prev_state" ]; then
            case "$state" in
                "1")
                    echo "二维码状态: 未扫描"
                    ;;
                "2")
                    echo "二维码状态: 已扫描"
                    ;;
                "3")
                    echo "二维码状态: 确认登录"
                    # 输出token和refreshToken
                    local token=$(echo "$response" | jq -r '.result.token')
                    local refreshToken=$(echo "$response" | jq -r '.result.refreshToken')
                    echo "登录成功!"
                    echo "Token: $token"
                    echo "Refresh Token: $refreshToken"
                    break
                    ;;
                *)
                    echo "未知状态: $state"
                    ;;
            esac
            prev_state="$state"
        fi
        sleep 1
    done
}

# 主函数
main() {
    check_dependencies
    
    local uuid
    generate_qrcode
    
    #echo "开始监控二维码状态 (UUID: $uuid)"
    query_qrcode_status "$uuid"
    
    echo "流程完成"
}

# 运行主函数
main "$@"
