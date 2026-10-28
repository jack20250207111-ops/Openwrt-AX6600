#!/bin/sh
# Real Docker End-to-End Drill Script for AX6600 Docker Upgrade Helper
# Designed to run in real Linux environments with active Docker daemon
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd -P)
HELPER_SCRIPT="$REPO_ROOT/Scripts/docker_upgrade_helper.sh"

log() {
    echo "[DRILL] $*"
}

log_err() {
    echo "[DRILL ERROR] $*" >&2
}

# 1. Check prerequisites
if ! command -v docker >/dev/null 2>&1; then
    log_err "Docker 未安装或不在 PATH 中，跳过真实 Docker 演练。"
    exit 0
fi

if ! docker info >/dev/null 2>&1; then
    log_err "Docker 守护进程未运行或无权限访问，跳过真实 Docker 演练。"
    exit 0
fi

# 2. Setup drill working directories
DRILL_ROOT=$(mktemp -d "/tmp/ax6600_docker_drill_XXXXXX" 2>/dev/null || mktemp -d -t 'ax6600_drill')
DRILL_BACKUP="$DRILL_ROOT/backup_target"
DRILL_RESTORE_DATA="$DRILL_ROOT/restored_dataroot"
DRILL_BIND_SRC="$DRILL_ROOT/host_bind_data"
DRILL_COMPOSE_DIR="$DRILL_ROOT/compose_proj"

mkdir -p "$DRILL_BACKUP" "$DRILL_RESTORE_DATA" "$DRILL_BIND_SRC" "$DRILL_COMPOSE_DIR"

cleanup() {
    log "正在清理真实演练容器与临时目录..."
    docker rm -f drill_standalone drill_compose_app 2>/dev/null || true
    docker rmi -f backup-snapshot-drill_standalone:latest 2>/dev/null || true
    rm -rf "$DRILL_ROOT"
}
trap cleanup EXIT INT TERM

log "=== 开始 AX6600 Docker 真实环境端到端演练 ==="
log "演练临时根目录: $DRILL_ROOT"

# 准备持久化绑定数据
echo "secret_bind_payload_v1" > "$DRILL_BIND_SRC/app_config.env"
echo "host_persistent_state_42" > "$DRILL_BIND_SRC/state.db"

# 3. 准备并启动真实独立容器 (包含环境变量、多段入口点、端口绑定与宿主卷挂载)
log "正在拉起演练独立容器 drill_standalone..."
docker rm -f drill_standalone 2>/dev/null || true

TEST_IMAGE="alpine:latest"
if ! docker image inspect "$TEST_IMAGE" >/dev/null 2>&1; then
    docker pull "$TEST_IMAGE" || true
fi

# 启动容器并写入运行时数据
docker run -d \
    --name drill_standalone \
    --restart unless-stopped \
    -e DRILL_ENV_VAR="ax6600_test_val_999" \
    -v "$DRILL_BIND_SRC:/data_host" \
    "$TEST_IMAGE" sh -c "echo 'container_internal_dirty_page' > /data_runtime.txt; sleep 3600"

sleep 1

# 写入容器可写层变动
docker exec drill_standalone sh -c "echo 'flush_data_before_shutdown' >> /data_runtime.txt"

# 4. 执行真实备份 (调用 helper 备份)
log "执行 helper 备份..."
sh "$HELPER_SCRIPT" backup \
    --target-dir "$DRILL_BACKUP"

# 5. 校验备份一致性产物
log "校验备份关键产物..."
if [ ! -f "$DRILL_BACKUP/backup_manifest.txt" ] || [ ! -f "$DRILL_BACKUP/sha256sums.txt" ]; then
    log_err "备份清单缺失！"
    exit 1
fi

(cd "$DRILL_BACKUP" && sha256sum -c sha256sums.txt) || {
    log_err "备份文件哈希校验自检失败！"
    exit 1
}

if [ ! -f "$DRILL_BACKUP/standalone/recreate_drill_standalone.sh" ]; then
    log_err "独立容器重建脚本未生成！"
    exit 1
fi

if [ ! -f "$DRILL_BACKUP/standalone/image_drill_standalone.tar" ]; then
    log_err "独立容器快照镜像未导出！"
    exit 1
fi

# 6. 清理原容器与原宿主数据，准备恢复演练
log "销毁原始容器并清空测试数据，模拟换盘或固件重置..."
docker rm -f drill_standalone 2>/dev/null || true
echo "corrupted_dirty_data" > "$DRILL_BIND_SRC/state.db"

# 7. 执行恢复 (调用 helper 恢复至新 DataRoot)
log "执行 helper 恢复..."
sh "$HELPER_SCRIPT" restore \
    --backup-dir "$DRILL_BACKUP" \
    --target-data-root "$DRILL_RESTORE_DATA"

# 8. 验收恢复结果
log "验收容器运行状态与数据一致性..."
if ! docker ps --format '{{.Names}}' | grep -q "drill_standalone"; then
    log_err "独立容器 drill_standalone 未成功恢复运行！"
    exit 1
fi

# 验证宿主持久化数据已准确覆盖还原
RESTORED_STATE=$(cat "$DRILL_BIND_SRC/state.db" 2>/dev/null || echo "")
if [ "$RESTORED_STATE" != "host_persistent_state_42" ]; then
    log_err "Bind Mount 持久化数据未正确恢复！实际值: $RESTORED_STATE"
    exit 1
fi

# 验证容器内部落盘数据（快照镜像还原）
RESTORED_INTERNAL=$(docker exec drill_standalone cat /data_runtime.txt 2>/dev/null || echo "")
if ! echo "$RESTORED_INTERNAL" | grep -q "flush_data_before_shutdown"; then
    log_err "容器内部快照数据未正确还原！实际值: $RESTORED_INTERNAL"
    exit 1
fi

# 验证容器环境变量
RESTORED_ENV=$(docker exec drill_standalone env 2>/dev/null | grep "^DRILL_ENV_VAR=" | cut -d= -f2- || true)
if [ "$RESTORED_ENV" != "ax6600_test_val_999" ]; then
    log_err "容器环境变量还原不匹配！实际值: $RESTORED_ENV"
    exit 1
fi

log "=== 真实 Docker 端到端演练全部通过！==="
exit 0
