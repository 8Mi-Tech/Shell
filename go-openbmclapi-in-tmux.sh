#!/bin/bash
case "`uname -m`" in
    x86_64)
        GOARCH="amd64"
    ;;
    i386|i686)
        GOARCH="386"
    ;;
    aarch64)
        GOARCH="arm64"
    ;;
    armv7l)
        GOARCH="arm"
    ;;
    *)
        echo "【8Mi & BMCLAPI】 未知处理器架构: `uname -m`,请将该架构报告到 https://github.com/LiterMC/go-openbmclapi/issues"
        exit
esac

FILE_NAME="./openbmclapi-go"
#REPROXY_URL="https://mirror.ghproxy.com/"
REPROXY_URL=""
URL="https://github.com/LiterMC/go-openbmclapi/releases/latest/download/go-openbmclapi-linux-$GOARCH"

while true; do
    if [ -e "$FILE_NAME" ]; then
        echo "【8Mi & BMCLAPI】 检测更新中"
        TAG_URL=`curl -sI $URL | grep "location: " | sed 's/location: //'`
        TAG=`$FILE_NAME version | grep 'Go-OpenBmclApi v' | sed -e "s/^Go-OpenBmclApi v.* (//" -e "s/)$//"`
        if [ -n "$TAG" ] && echo "$TAG_URL" | grep -qF "$TAG"; then
            echo "【8Mi & BMCLAPI】 无需更新."
            NEED_DL=false
        else
            NEED_DL=true
        fi
    else
        NEED_DL=true
    fi

    if [ "$NEED_DL" = true ]; then
        echo "【8Mi & BMCLAPI】 开始下载"
        while true; do
            wget --show-progress -qO "$FILE_NAME" "$REPROXY_URL$URL"
            if [ $? -eq 0 ]; then
                break
            fi
            sleep 1
        done
    fi

    chmod +x $FILE_NAME; $FILE_NAME; sleep 1
done
