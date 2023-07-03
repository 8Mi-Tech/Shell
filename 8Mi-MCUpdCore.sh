#!/bin/bash
# 8Mi-Tech Original

# 使用方法
# 在自己的shell文件内写入如下内容 即可调用本文件的指令
# !/bin/bash
# source 8Mi-MCUpdCore.sh

# jenkins_getLatestDLURL
# $1 = * URL (example "https://ci.viaversion.com/job/ViaVersion-DEV")
# $2 = * ArtifactID(default:0) (example 0)
jenkins_getLatestDLURL(){
    echo $1/lastSuccessfulBuild/artifact/`wget -qO- $1/lastSuccessfulBuild/api/json | jq -r ".artifacts[${2:-0}].relativePath"` >&1
}

# curseforge_getLatestDLURL
# $1 = * App/Type/Name (example "minecraft/mc-mods/fabric-api")
# $2 =   Game_Version (example "1.20.1")
curseforge_getLatestDLURL(){
    cf_json=`wget -qO- "https://api.cfwidget.com/"$1"?version="$2`
    cf_file_id=`echo $cf_json | jq '.download.id'`
    cf_file_name=`echo $cf_json | jq -r '.download.name'`
    if [ $cf_file_id ]; then
        cf_file_id_url=`echo $cf_file_id | sed 's/..../&\//g'`
        if [ ${cf_file_id_url: -1} != \/ ]; then
        cf_file_id_url=$cf_file_id_url\/
        fi
    cf_file_id_url=`echo $cf_file_id_url | sed 's/\/00/\//g'`
    cf_file_id_url=`echo $cf_file_id_url | sed 's/\/0/\//g'`
    cf_file_name=`echo $cf_file_name|sed 's/+/%2B/g'`
    echo "https://media.forgecdn.net/files/"$cf_file_id_url$cf_file_name >&1
    fi
}

# modrinth_getLatestDLURL
# $1 = * Project(Name/ID) (example "fabric-api" or "P7dR8mSH")
# $2 =   GameVersion (example "1.20.1")
modrinth_getLatestDLURL(){
    if [ !$2 ]; then
    modrinth_gameversion=`wget -qO- https://api.modrinth.com/v2/tag/game_version | jq -r .[0].version`
    fi
    wget -qO- https://api.modrinth.com/v2/project/$1/version?game_versions=[%22${2:-$modrinth_gameversion}%22] | jq -r .[0].files[0].url >&1
}

# papermc_getLatestDLURL
# $1 = * Name (Tips visit: https://api.papermc.io/v2/projects)
# $2 =   GameVersion (example 1.20.1)
#                    (if not set version, default get minecraft's latest version)
papermc_getLatestDLURL() {
    if [ `wget -qO- https://api.papermc.io/v2/projects | jq ".projects|index(\"$1\")"` != "null" ]; then
        papermc_url="https://api.papermc.io/v2/projects/"$1
        papermc_url=$papermc_url"/versions/"${2:-`wget -qO- $papermc_url | jq -r ".versions[-1]"`}
        papermc_url=$papermc_url"/builds/"`wget -qO- $papermc_url | jq -r ".builds[-1]"`
        papermc_url=$papermc_url"/downloads/"`wget -qO- $papermc_url | jq -r ".downloads.application.name"`
        echo "$papermc_url" >&1
    else
        echo "papermc not have "$1 >&2
    fi
}

# 8Mi_Download
# $1 = * FileName (example FabricAPI.jar)
# $2 =   Download URL (support STDIN) (example https://example.com/fabric-api/fabric-api-1.0-1.20.1.jar) 
8Mi_Download(){
    dl_url=`cat /dev/stdin`
    echo "[8Mi-MCUpdCore] 正在通过服务器"` echo ${2:-$dl_url} | awk -F'/' '{print $3}' `" 下载"$1
    wget --show-progress -qO ./_tmp-ci/$1 ${2:-$dl_url}
    if [ 0 -ne $? ]; then
    echo "[8Mi-MCUpdCore] "$1"下载失败"
    fi
}