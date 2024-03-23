#!/bin/bash
# 8Mi-Tech Original

# 使用方法
# 在自己的shell文件内写入如下内容 即可调用本文件的指令
# !/bin/bash
# source 8Mi-MCUpdCore.sh

# 初始化(关于Wget)
wget --help | grep -q '\--show-progress' && WGET_PROGRESS_OPT="-q --show-progress" || WGET_PROGRESS_OPT=""

# jenkins_getLatestDLURL
# $1 = * URL (example "https://ci.viaversion.com/job/ViaVersion-DEV")
# $2 = * ArtifactID(default:0) (example 0)
jenkins_getLatestDLURL(){
    echo $1/lastSuccessfulBuild/artifact/`curl -s $1/lastSuccessfulBuild/api/json | jq -r ".artifacts[${2:-0}].relativePath"` >&1
}

# curseforge_getLatestDLURL
# $1 = * App/Type/Name (example "minecraft/mc-mods/fabric-api")
# $2 =   Game_Version (example "1.20.1")
# $2 =   Mod_Loader_Name (example "fabric" "forge" "neoforge")
curseforge_getLatestDLURL(){
    cf_json=`curl -s "https://api.cfwidget.com/$1?version=$2&loader=$3"`
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
# $2 =   Mod_Loader_Name (example "fabric" "forge" "neoforge")
modrinth_getLatestDLURL(){
    local modrinth_game_version_latest=""
    local modrinth_url_base=""
    local modrinth_game_versions=""
    local modrinth_loaders=""
    if [ !$2 ]; then
        modrinth_game_version_latest=`curl -s https://api.modrinth.com/v2/tag/game_version | jq -r .[0].version`
    fi
    modrinth_url_base="https://api.modrinth.com/v2/project/$1/version"
    modrinth_game_versions="game_versions=[%22${2:-$modrinth_game_version_latest}%22]"
    if [ "$3" ]; then
        modrinth_loaders="loaders=[%22${3}%22]"
    fi
    curl -s "$modrinth_url_base?$modrinth_game_versions&$modrinth_loaders" | jq -r .[0].files[0].url >&1
}

# papermc_getLatestDLURL
# $1 = * Name (Tips visit: https://api.papermc.io/v2/projects)
# $2 =   GameVersion (example 1.20.1)
#                    (if not set version, default get minecraft's latest version)
papermc_getLatestDLURL() {
    local papermc_url=""
    if [ `curl -s https://api.papermc.io/v2/projects | jq ".projects|index(\"$1\")"` != "null" ]; then
        papermc_url="https://api.papermc.io/v2/projects/"$1
        papermc_url=$papermc_url"/versions/"${2:-`curl -s $papermc_url | jq -r ".versions[-1]"`}
        papermc_url=$papermc_url"/builds/"`curl -s $papermc_url | jq -r ".builds[-1]"`
        papermc_url=$papermc_url"/downloads/"`curl -s $papermc_url | jq -r ".downloads.application.name"`
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
    wget $WGET_PROGRESS_OPT -O ./_tmp-ci/$1 ${2:-$dl_url}
    if [ 0 -ne $? ]; then
        echo "[8Mi-MCUpdCore] "$1"下载失败"
    fi
}
