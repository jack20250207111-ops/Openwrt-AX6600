#!/bin/bash

# =============================================
# 安全更新和安装 OpenWrt 插件脚本
# =============================================

set -e

# 检查依赖工具是否存在
CHECK_DEPENDENCIES() {
    local deps=("git" "curl" "sha256sum" "jq")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo "[WARN] Dependency missing: $dep"
        fi
    done
}
CHECK_DEPENDENCIES

# 安全更新/安装包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
    local PKG_REPO=$2
    local PKG_BRANCH=$3
    local PKG_SPECIAL=${4:-""}   # pkg 或 name，可选
    local PKG_LIST=($5)          # 可选自定义名称列表
    local REPO_NAME=${PKG_REPO#*/}

    echo -e "\n=== Processing package: $PKG_NAME ==="

    # 删除本地旧目录（安全检查）
    if [ ${#PKG_LIST[@]} -eq 0 ]; then
        PKG_LIST=($PKG_NAME)
    fi

    for NAME in "${PKG_LIST[@]}"; do
        FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)
        if [ -n "$FOUND_DIRS" ]; then
            while read -r DIR; do
                echo "[DELETE] Removing $DIR"
                rm -rf "$DIR"
            done <<< "$FOUND_DIRS"
        else
            echo "[SKIP] No existing directory found for $NAME"
        fi
    done

    # 克隆 GitHub 仓库
    echo "[CLONE] git clone --branch $PKG_BRANCH https://github.com/$PKG_REPO.git"
    git clone --depth=1 --single-branch --branch "$PKG_BRANCH" "https://github.com/$PKG_REPO.git" || {
        echo "[ERROR] Failed to clone $PKG_REPO"
        return 1
    }

    # 处理特殊包
    if [[ "$PKG_SPECIAL" == "pkg" ]]; then
        FOUND_SUBDIR=$(find ./$REPO_NAME -maxdepth 3 -type d -iname "*$PKG_NAME*" | head -n1)
        if [ -z "$FOUND_SUBDIR" ]; then
            echo "[ERROR] Subdirectory $PKG_NAME not found in $REPO_NAME"
        else
            cp -rf "$FOUND_SUBDIR" ./ || echo "[WARN] Copy failed for $PKG_NAME"
        fi
        rm -rf ./$REPO_NAME
    elif [[ "$PKG_SPECIAL" == "name" ]]; then
        mv -f $REPO_NAME $PKG_NAME
    fi

    echo "[DONE] $PKG_NAME processed"
}

# 自动更新 GitHub Release 版本（可选）
UPDATE_VERSION() {
    local PKG_NAME=$1
    local PKG_MARK=${2:-false}  # 是否测试版

    PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")
    if [ -z "$PKG_FILES" ]; then
        echo "[SKIP] $PKG_NAME not found!"
        return
    fi

    echo "[UPDATE] $PKG_NAME version check started"

    for PKG_FILE in $PKG_FILES; do
        PKG_REPO=$(grep -Po "PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)" $PKG_FILE)
        PKG_TAG=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease == $PKG_MARK)) | first | .tag_name")
        OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")
        NEW_VER=$(echo $PKG_TAG | sed -E 's/[^0-9]+/\./g; s/^\.|\.$//g')
        if dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
            sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
            echo "[UPDATE] $PKG_FILE version updated: $OLD_VER -> $NEW_VER"
        else
            echo "[INFO] $PKG_FILE already latest version"
        fi
    done
}

# =============================================
# 示例：更新常用插件
# =============================================
UPDATE_PACKAGE "aurora" "ones20250/luci-theme-aurora" "master"
UPDATE_PACKAGE "aurora-config" "ones20250/luci-app-aurora-config" "master"
#UPDATE_PACKAGE "aurora" "ones20250/luci-theme-aurora" "master"
#UPDATE_PACKAGE "aurora-config" "ones20250/luci-app-aurora-config" "master"


#UPDATE_PACKAGE "homeproxy" "ones20250/homeproxy" "master"
#UPDATE_PACKAGE "momo" "nikkinikki-org/OpenWrt-momo" "main"
#UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main"
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "master" "pkg"
UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"
UPDATE_PACKAGE "luci-app-passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "luci-app-passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"

#UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"

#UPDATE_PACKAGE "luci-app-tailscale" "asvow/luci-app-tailscale" "main"

#UPDATE_PACKAGE "ddns-go" "sirpdboy/luci-app-ddns-go" "main"
#UPDATE_PACKAGE "diskman" "lisaac/luci-app-diskman" "master"
#UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"
#UPDATE_PACKAGE "fancontrol" "rockjake/luci-app-fancontrol" "main"
#UPDATE_PACKAGE "gecoosac" "laipeng668/luci-app-gecoosac" "main"
# 可选择性更新版本
# UPDATE_VERSION "tailscale" true
