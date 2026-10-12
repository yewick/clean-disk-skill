---
name: clean_disk
description: 扫描并定位 macOS/Windows 系统中的垃圾文件、缓存、日志、包管理器缓存与废纸篓/回收站等可清理内容并计算占用空间,生成磁盘清理与性能优化建议。当用户提到磁盘空间不足、清理垃圾/缓存、释放空间、clean disk、storage cleanup 时使用。
license: MIT
---

请先运行 `scripts/get_system_info` 系列脚本获取当前电脑系统信息,并据此判断操作系统类型:

- macOS / Darwin → 使用 `scripts/get_system_info.sh` 与 `scripts/check_cleanable_files.sh`
- Windows → 使用 `scripts/get_system_info.ps1` 与 `scripts/check_cleanable_files.ps1`

随后运行对应的扫描脚本,分析系统中的可清理内容和空间占用情况(按占用大小从高到低排序)。

最后参考 `references/reference.md` 的表达风格,针对当前电脑生成磁盘清理与性能优化建议,
使用命令式、部署式的表达方式。

约束:
- 默认只做扫描与建议,不自动删除任何文件。
- 即使用户要求代为清理,也只能先列出建议的命令;须等用户对每一项明确确认后,才可执行——即便是「可删」级别也不例外,绝不擅自自动删除。
- 「禁删」级别的系统组件(WinSxS、Windows\Installer 等)只能用官方工具(DISM/磁盘清理)处理,绝不使用 rm 等命令。
