# clean-disk-skill

一个用于 macOS 与 Windows 的**磁盘清理扫描 Agent Skill**。它会先获取系统信息并判断操作系统,扫描可清理的垃圾文件与缓存,再以「命令式、部署式」的风格输出清理建议。

> 本 skill 只做扫描与建议,**绝不自动删除任何文件**,所有删除操作都需你手动确认。

## 功能介绍

- **跨平台识别**:自动判断 macOS / Windows,调用对应脚本。
- **系统信息**:主机、系统版本、CPU、内存、磁盘使用率、网络 IP。
- **垃圾扫描**(macOS):用户/系统缓存、日志、废纸篓、Xcode 派生数据、浏览器缓存、Homebrew / npm / Yarn / Maven / Gradle / CocoaPods 缓存、Docker 悬空资源、下载文件夹。
- **C 盘深度排查**(Windows):系统隐藏大块(休眠文件、页面文件、崩溃转储、系统还原点、Windows.old、更新缓存、WinSxS、Installer 等)、用户缓存,以及常驻 C 盘的软件数据(微信 / QQ / 企业微信 / 网盘 / 游戏等,提醒迁移位置)。
- **安全分级标签**:`[A 可删]` / `[B 谨慎]` / `[C 禁删]` / `[M 迁移]`,一眼看清哪些能碰、哪些要绕开。
- **部署式建议**:参考 `references/reference.md`,以「你记一下,我作如下清理部署调整——」的作战命令风格输出优化建议。

## 目录结构

```
clean_disk/
├── SKILL.md                        # skill 入口(元数据 + 流程指令)
├── scripts/
│   ├── get_system_info.sh          # macOS 系统信息
│   ├── check_cleanable_files.sh    # macOS 可清理扫描
│   ├── get_system_info.ps1         # Windows 系统信息
│   └── check_cleanable_files.ps1   # Windows C 盘深度排查
└── references/
    └── reference.md                # 命令式/部署式表达风格
```

## 安装方法

Skill 需放到 Claude Code 能扫描到的目录:

```bash
# 全局(所有项目可用)
ln -sfn /path/to/clean_disk ~/.claude/skills/clean_disk

# 或项目级(仅某个项目可用)
ln -sfn /path/to/clean_disk <项目>/.claude/skills/clean_disk
```

重启 Claude Code 会话后生效。

## 使用方法

1. 在 Claude Code 中输入 `/clean_disk`,或直接说「帮我清理磁盘」「空间不足了」。
2. Skill 会先获取系统信息、判断是 macOS 还是 Windows,再运行对应的扫描脚本。
3. 根据扫描结果,以部署式风格给出清理建议。

## 安全说明

- **只扫描、不删除**:脚本本身不会删除任何文件。
- **不自动清理**:即便要求代为清理,也只列出命令,须你逐项确认后才执行;「禁删」级系统组件只用官方工具(DISM / 磁盘清理)处理,绝不用 `rm`。
- 危险操作前请务必确认路径。

## License

[MIT](./LICENSE)
