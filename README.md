# 🚀 OpenWrt AX6600 / IPQ60xx Router Firmware (Cloud Build + NSS Acceleration)

OpenWrt / AX6600 / IPQ6010 / JDCloud RE-CS-02 / NSS / Router Firmware / Cloud Build
> 基于 OpenWrt / ImmortalWrt 的定制固件，适配 JDCloud RE-CS-02（京东云雅典娜 AX6600），集成 NSS 硬件加速优化与 GitHub Actions 自动云编译

[👉 进入项目主页](https://github.com/ones20250/Openwrt-AX6600)
---

## ⭐ 项目特点

- 🔥 **云编译构建** - 基于 GitHub Actions 完全自动化编译
- 📦 **官方支持** - 完美适配京东云雅典娜AX6600（RE-CS-02）
- 🚀 **开箱即用** - 预装常用网络工具与插件
- ⚡ **硬件加速** - 原生支持 NSS 硬件加速引擎
- 🌐 **性能优化** - 显著提升 NAT/转发/吞吐性能
- 🔄 **源码同步** - 自动跟进 OpenWrt/ImmortalWrt 最新上游
- 🧩 **灵活定制** - 支持自定义编译配置和插件

---

## 📥 快速开始

### 1️⃣ 下载固件
🎯 **[👉 点击下载最新固件](https://github.com/ones20250/Openwrt-AX6600/releases/latest)**

所有编译产物都在 Releases 页面发布，选择最新版本下载。

📦 **刷机相关文件（Bootloader / 工具 / 备用固件）**
👉 **[点击下载刷机文件](https://github.com/ones20250/Openwrt-AX6600/releases/tag/Router-Flashing-Files)**

---

## 🛠️ 刷机指南

> ⚠️ **重要提示：** 以下操作涉及 U-Boot 和分区修改，**请务必先备份重要数据**，谨慎操作！

### 详细教程
📖 **[完整刷机图文教程 →](https://blog.waynecommand.com/post/athena-re-cs-02.html)**（推荐新手参考）

### 刷机步骤

1. **启用 SSH 访问**
   - 进入旧版本固件管理后台
   - 启用 SSH 服务

2. **备份分区**（二选一）
   - 通过 SSH 备份分区数据
   - 或使用 TTL 串口备份（更安全）

3. **刷入 U-Boot**
   - 安装不死 U-Boot（防砖）
   - 更新双分区 GPT 分区表

4. **创建存储分区**
   - 新建 storage 分区
   - 恢复跑分分区数据

5. **刷入固件**
   - 从 Releases 下载最新固件
   - 通过 U-Boot Web 界面刷入

---

## 📋 固件说明

| 说明 | 详情 |
|------|------|
| **编译时间** | 显示的时间为编译开始时间，用于对应上游源码版本 |
| **版本划分** | 默认同时构建 `PURE` 纯净版与 `RICH` 丰富版 |
| **基础功能** | 纯净版保持当前轻量配置，包含完整网络功能栈 |
| **扩展插件** | 丰富版额外集成 Docker / Dockerman、PassWall / PassWall2、OpenClash、AdGuard Home 等常用组件，也可通过自定义配置 `.config` 文件继续增加插件 |
| **硬件平台** | 基于 QUALCOMMAX（IPQ6010）架构 |
| **性能优化** | 针对 IPQ6010 平台进行网络性能调优 |

---


### 固件版本

| 版本 | 适合人群 | 预置内容 |
|------|----------|----------|
| `PURE` 纯净版 | 希望系统轻量、稳定，按需自行安装插件的用户 | 保持当前配置，预装基础网络与常用管理插件 |
| `RICH` 丰富版 | 希望刷完即用常见扩展服务的用户 | 在纯净版基础上增加 Docker / Dockerman、PassWall / PassWall2、OpenClash、AdGuard Home |

> 💡 Releases 中的文件名会包含 `pure` 或 `rich`，请按需求下载对应版本。

### 版本与验证建议

- `PURE`：推荐作为日常稳定版，保持当前轻量配置。
- `RICH`：丰富版会额外集成 Docker / Dockerman、PassWall / PassWall2、OpenClash、AdGuard Home，固件体积和运行资源占用都会明显高于纯净版。
- 手动测试时可在 `WRT-TEST` 工作流选择 `PROFILE=PURE` 或 `PROFILE=RICH`；建议丰富版发布前至少先用 `TEST=true` 生成最终 `.config`，再用完整编译确认上游插件依赖没有变化。
- Release 会额外上传 `Packages-*.txt` 记录丰富版外部插件仓库、分支和 commit，方便排查 OpenClash / PassWall / PassWall2 上游变更导致的编译问题。丰富版还会额外加入 PassWall/PassWall2 feeds，并显式拉取 `luci-app-passwall` 与 `luci-app-passwall2`，避免出现“编译成功但系统里没有插件入口”的情况。

> ⚠️ 丰富版依赖外部插件仓库和上游 feeds，若上游调整包名或依赖，可能需要同步更新 `Config/GENERAL_AX6600_RICH.txt`。

## 📂 项目结构

| 目录/文件 | 用途 | 说明 |
|----------|------|------|
| `.github/workflows/` | CI/CD 自动编译 | 定义 GitHub Actions 工作流，实现云端自动构建 |
| `scripts/` | 编译脚本 | 包含编译前置处理、自定义配置等辅助脚本 |
| `config/` | 编译配置 | 存放 OpenWrt `.config` 配置文件 |

---

## 🔗 上游源码与依赖

### 📦 OpenWrt 源码仓库

| 版本 | 仓库地址 | 说明 |
|------|---------|------|
| **官方版** | [immortalwrt/immortalwrt](https://github.com/immortalwrt/immortalwrt.git) | ImmortalWrt 官方仓库 |
| **高通专用版** | [ones20250/immortalwrt_ipq](https://github.com/ones20250/immortalwrt_ipq.git) | IPQ 平台优化版本 |

### 🔧 U-Boot 固件仓库

| 平台 | 仓库地址 | 说明 |
|------|---------|------|
| **eMMC 版本** | [chenxin527/uboot-ipq60xx-emmc-build](https://github.com/chenxin527/uboot-ipq60xx-emmc-build) | eMMC 存储设备专用 |
| **NOR Flash 版本** | [chenxin527/uboot-ipq60xx-nor-build](https://github.com/chenxin527/uboot-ipq60xx-nor-build) | NOR Flash 存储设备专用 |

> 💡 **提示：** U-Boot 版本选择需与您的设备硬件配置相匹配，错误选择会导致设备无法启动！

---

## 🚀 自定义编译

### 修改编译配置

编辑 `config/.config` 文件，按需调整编译选项：

```bash
# 克隆仓库
git clone https://github.com/ones20250/Openwrt-AX6600.git
cd Openwrt-AX6600

# 编辑配置文件
nano config/.config

# 提交更改（可选）
git add config/.config
git commit -m "feat: 更新编译配置"
git push origin main
```
### 触发编译

提交代码后，GitHub Actions 会自动开始编译，编译完成后固件将发布到 Releases 页面。

---

## 📊 固件特性对比

| 特性 | 原厂固件 | 本项目固件 |
|------|---------|----------|
| **OpenWrt 版本** | 不支持 | ✅ 最新版 |
| **NSS 硬件加速** | ⚠️ 部分支持 | ✅ 完全支持 |
| **网络性能** | 基础 | ✅ 优化增强 |
| **自定义插件** | ❌ 不支持 | ✅ 完全支持 |
| **定期更新** | ❌ 不定期 | ✅ 自动更新 |
| **开源透明** | ❌ 闭源 | ✅ 开源公开 |

---

## 🔐 安全建议

### ⚠️ 刷机前必读

1. **备份所有数据**
   ```bash
   # SSH 连接到设备
   ssh root@192.168.1.1
   
   # 备份整个 U-Boot 分区
   dd if=/dev/mtd0 of=/tmp/uboot.bin
   
   # 备份分区表
   dd if=/dev/mtd1 of=/tmp/partition_table.bin
   ``
2. **验证文件完整性**
   ```bash
   # 下载固件和校验和文件
   # 验证 SHA256
   sha256sum -c firmware.bin.sha256
   ``
3. **准备恢复方案**
   - 保留 TTL 串口工具
   - 准备原厂固件备份
   - 了解救砖流程

### 🛡️ 常见风险及预防

| 风险 | 症状 | 预防方法 |
|------|------|---------|
| **U-Boot 错误** | 设备无法启动 | 使用不死 U-Boot，备份原件 |
| **分区错误** | 系统无法识别 | 使用正确的 GPT 分区表 |
| **断电** | 刷机中断 | 使用 UPS 或稳定电源 |
| **固件损坏** | 开机无响应 | 验证 SHA256 后再刷入 |


## ⚠️ 免责声明

刷机有风险，操作需谨慎。

本项目固件仅供学习与研究使用，请确认设备型号匹配并提前备份数据。
因刷机造成的设备损坏或数据丢失，作者不承担任何责任。

