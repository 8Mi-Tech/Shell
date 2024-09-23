#!/bin/bash
# 8Mi-Tech Original

# 使用方法
# 在自己的shell文件内写入如下内容 即可调用本文件的指令
# !/bin/bash
# source 8Mi-MCUpdCore.sh

# jenkins_getLatestUrl
# $1 = * URL (example "https://ci.viaversion.com/job/ViaVersion-DEV")
# $2 = * ArtifactID(default:0) (example 0)
jenkins_getLatestUrl(){
    echo $1/lastSuccessfulBuild/artifact/`wget -qO- $1/lastSuccessfulBuild/api/json | jq -r ".artifacts[${2:-0}].relativePath"` >&1
}

# curseforge_getLatestUrl
# $1 = * App/Type/Name (example "minecraft/mc-mods/fabric-api")
# $2 =   Game_Version (example "1.20.1")
curseforge_getLatestUrl(){
    local cf_json=`wget -qO- "https://api.cfwidget.com/"$1"?version="$2`
    local cf_file_id=`echo $cf_json | jq '.download.id'`
    local cf_file_name=`echo $cf_json | jq -r '.download.name'`
    if [ $cf_file_id ]; then
        local cf_file_id_url=`echo $cf_file_id | sed 's/..../&\//g'`
        if [ ${cf_file_id_url: -1} != \/ ]; then
        cf_file_id_url=$cf_file_id_url\/
        fi
    cf_file_id_url=`echo $cf_file_id_url | sed 's/\/00/\//g'`
    cf_file_id_url=`echo $cf_file_id_url | sed 's/\/0/\//g'`
    cf_file_name=`echo $cf_file_name|sed 's/+/%2B/g'`
    echo "https://media.forgecdn.net/files/"$cf_file_id_url$cf_file_name >&1
    fi
}

# modrinth_getLatestUrl
# * --project = Project(Name/ID) (example "fabric-api" or "P7dR8mSH")
#   --game_versions = GameVersion (example "1.20.1" "1.18,1.19")
#   --loaders = Loaders (example "velocity" "velocity,bukkit")
#   --type = Version Type (example "release" "beta" "alpha")
modrinth_getLatestUrl() {
    query_list=()
    _parse_array() {
        echo "$1" | jq -R -c 'if contains(",") then split(",") else [.] end' | jq -sRr @uri
    }
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project)
                local project="$2"
                shift 2
                ;;
            --game_versions)
                local query_list+=("game_versions="$(_parse_array "$2"))
                shift 2
                ;;
            --loaders)
                local query_list+=("loaders="$(_parse_array "$2"))
                shift 2
                ;;
            --type)
                if ! [[ "$2" =~ ^(release|beta|alpha)$ ]]; then
                    echo "Invalid version type: $2"
                    return 1
                fi
                local query_list+=("version_type=$2")
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done
    if [ ${#query_list[@]} -gt 0 ]; then local question="?"; fi
    IFS='&' # 设置分隔符
    local query_list_str="${query_list[*]}" # 连接数组元素
    unset IFS # 还原 IFS
    curl -sL "https://api.modrinth.com/v2/project/$project/version$question$query_list_str" | jq -r .[0].files[0].url >&1
}
# papermc_getLatestUrl
# $1 = * Name (Tips visit: https://api.papermc.io/v2/projects)
# $2 =   GameVersion (example 1.20.1)
#                    (if not set version, default get minecraft's latest version)
papermc_getLatestUrl() {
    if [ `wget -qO- https://api.papermc.io/v2/projects | jq ".projects|index(\"$1\")"` != "null" ]; then
        local papermc_url="https://api.papermc.io/v2/projects/"$1
        papermc_url=$papermc_url"/versions/"${2:-`wget -qO- $papermc_url | jq -r ".versions[-1]"`}
        papermc_url=$papermc_url"/builds/"`wget -qO- $papermc_url | jq -r ".builds[-1]"`
        papermc_url=$papermc_url"/downloads/"`wget -qO- $papermc_url | jq -r ".downloads.application.name"`
        echo "$papermc_url" >&1
    else
        echo "papermc not have "$1 >&2
    fi
}

# luckperms_getLatestUrl
# $1 = * Platform (example "bukkit" "velocity")
luckperms_getLatestUrl(){ curl -s "https://metadata.luckperms.net/data/all" | jq -r .downloads.$1; }

# 8Mi_Download
# $1 = * FileName (example FabricAPI.jar)
# $2 =   Download URL (support STDIN) (example https://example.com/fabric-api/fabric-api-1.0-1.20.1.jar) 
8Mi_Download(){
    local dl_url=`cat /dev/stdin`
    cd _tmp-ci
    echo "[8Mi-MCUpdCore] 正在通过服务器"` echo ${2:-$dl_url} | awk -F'/' '{print $3}' `" 下载"$1
    wget --show-progress -qO $1 ${2:-$dl_url}
    if [ 0 -ne $? ]; then
    echo "[8Mi-MCUpdCore] "$1"下载失败"
    fi
    cd - >> /dev/null
}
