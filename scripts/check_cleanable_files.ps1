# check_cleanable_files.ps1
# 脚本功能：深度扫描 Windows 系统中 C 盘空间被占用的三大来源——
#   1) 系统级隐藏大块（休眠/页面文件、崩溃转储、系统还原点、Windows.old、更新缓存等）
#   2) 用户级缓存与临时文件（临时目录、浏览器、包管理器、回收站）
#   3) 常驻 C 盘的软件数据（微信/QQ/网盘/游戏等，提示迁移存放位置）
# 每个条目都带安全标签：[A 可删] / [B 谨慎] / [C 禁删] / [M 迁移]
# 注意：此脚本仅进行扫描和列举，不会删除任何文件。

Write-Host "============================================================"
Write-Host "           Windows C 盘空间深度排查                         "
Write-Host "============================================================"
Write-Host "正在扫描，请稍候（部分系统目录需管理员权限才能读取大小）..."
Write-Host ""

Write-Host "标签图例："
Write-Host "  [A 可删]  纯缓存/临时文件，删了自动重建，可安全清理" -ForegroundColor Green
Write-Host "  [B 谨慎]  可能有价值(回滚/恢复/排查)或有代价，删前需确认" -ForegroundColor Yellow
Write-Host "  [C 禁删]  手动删会破坏系统，只能用官方工具" -ForegroundColor Red
Write-Host "  [M 迁移]  软件数据，非垃圾，建议迁移到其他盘，不要删" -ForegroundColor Cyan
Write-Host ""

# ================= 工具函数 =================

function Format-Size {
    param([double]$Bytes)
    if ($Bytes -ge 1TB) { return ("{0:N2} TB" -f ($Bytes / 1TB)) }
    elseif ($Bytes -ge 1GB) { return ("{0:N2} GB" -f ($Bytes / 1GB)) }
    elseif ($Bytes -ge 1MB) { return ("{0:N2} MB" -f ($Bytes / 1MB)) }
    elseif ($Bytes -ge 1KB) { return ("{0:N2} KB" -f ($Bytes / 1KB)) }
    else { return "$Bytes B" }
}

function Get-ItemSizeBytes {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) {
        $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        if ($null -eq $item) { return $null }
        if ($item.PSIsContainer) {
            $sum = (Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum
            if ($null -eq $sum) { $sum = 0 }
            return $sum
        }
        else {
            return $item.Length
        }
    }
    return $null
}

function Show-Item {
    param(
        [string]$Name,
        [string]$Path,
        [string]$Level,
        [string]$Desc,
        [string]$Action = ""
    )
    $sizeBytes = Get-ItemSizeBytes -Path $Path
    if ($null -ne $sizeBytes) {
        $labelText = switch ($Level) {
            "A" { "[A 可删]" }
            "B" { "[B 谨慎]" }
            "C" { "[C 禁删]" }
            "M" { "[M 迁移]" }
            default { "" }
        }
        $labelColor = switch ($Level) {
            "A" { "Green" }
            "B" { "Yellow" }
            "C" { "Red" }
            "M" { "Cyan" }
            default { "White" }
        }
        Write-Host "[$Name]  " -NoNewline -ForegroundColor Yellow
        Write-Host $labelText -ForegroundColor $labelColor
        Write-Host "  路径: $Path"
        Write-Host "  大小: $(Format-Size -Bytes $sizeBytes)" -ForegroundColor Red
        Write-Host "  说明: $Desc"
        if ($Action) { Write-Host "  建议: $Action" -ForegroundColor Green }
        Write-Host "------------------------------------------------------------"
    }
}

# ================= 一、系统级隐藏大块 =================

Write-Host "================== 一、系统级隐藏大块 ==================" -ForegroundColor Cyan
Write-Host "(普通用户在资源管理器里看不到，却常是 C 盘爆满的真凶)"

Show-Item "休眠文件 hiberfil.sys" "$env:SystemDrive\hiberfil.sys" "B" "系统休眠功能产生，通常为内存的 40%~75%，动辄数 GB。" "若不用休眠：以管理员运行 'powercfg /hibernate off'（代价：失去休眠与快速启动）。"

Show-Item "虚拟内存页面文件 pagefile.sys" "$env:SystemDrive\pagefile.sys" "B" "系统虚拟内存，功能文件，不是垃圾。" "不建议手动删；可在「高级系统设置 → 性能 → 虚拟内存」改到其他盘或调小。"

Show-Item "交换文件 swapfile.sys" "$env:SystemDrive\swapfile.sys" "B" "UWP 应用使用的交换文件，功能文件。" "一般无需处理。"

Show-Item "系统崩溃转储 MEMORY.DMP" "$env:SystemRoot\MEMORY.DMP" "B" "蓝屏时的完整内存转储，排查蓝屏时可能还需要。" "确认无需排查后，可到「系统属性 → 启动和故障恢复」关闭转储。"

Show-Item "蓝屏小型转储 Minidump" "$env:SystemRoot\Minidump" "B" "蓝屏小型转储文件，排查蓝屏时可能还需要。" "确认后清空旧文件。"

Show-Item "内核实时报告 LiveKernelReports" "$env:SystemRoot\LiveKernelReports" "B" "内核实时报告转储，排查问题时可能还需要。" "确认后清空。"

# 系统还原点（vssadmin 需管理员权限）
Write-Host "[系统还原点]  " -NoNewline -ForegroundColor Yellow
Write-Host "[B 谨慎]" -ForegroundColor Yellow
$shadow = vssadmin list shadowstorage 2>$null
if ($LASTEXITCODE -eq 0 -and $shadow) {
    $shadow | Where-Object { $_ -match '空间|Space|GB|MB' } | ForEach-Object { Write-Host "  $_" }
    Write-Host "  说明: 系统还原点用于回滚，删旧还原点会失去回滚能力。"
    Write-Host "  建议: 「系统保护」中调小还原点配额，或「磁盘清理 → 清理系统文件 → 系统还原」删除旧还原点。" -ForegroundColor Green
}
else {
    Write-Host "  说明: 需管理员权限才能读取还原点占用。"
    Write-Host "  建议: 控制面板 → 系统 → 系统保护 查看还原点配额。" -ForegroundColor Green
}
Write-Host "------------------------------------------------------------"

Show-Item "旧系统 Windows.old" "$env:SystemDrive\Windows.old" "B" "系统大版本升级后遗留的旧系统，回滚窗口内可能还需要。" "确认新系统稳定后，用「磁盘清理 → 清理系统文件 → 以前的 Windows 安装」删除。"

Show-Item "Windows 更新缓存" "$env:SystemRoot\SoftwareDistribution\Download" "B" "Windows 更新下载的补丁缓存，系统自行管理。" "交给「磁盘清理 → 清理系统文件」，不要手动删。"

Show-Item "传递优化(P2P)缓存" "$env:SystemRoot\SoftwareDistribution\DeliveryOptimization" "B" "Win10/11 传递优化缓存。" "可在「设置 → 更新 → 传递优化」关闭，或清空该目录。"

Show-Item "安装程序缓存 Installer" "$env:SystemRoot\Installer" "C" "各程序的卸载/修复补丁，删了会导致无法卸载或修复。" "勿手动删！可用 PatchCleaner 等工具清理孤儿补丁。"

Show-Item "Windows 临时目录" "$env:SystemRoot\Temp" "A" "系统级临时文件。" "可清空（被占用的文件会自动跳过）。"

Show-Item "WinSxS 组件存储" "$env:SystemRoot\WinSxS" "C" "系统组件库，显示大小虚高（含硬链接），删了会破坏系统。" "勿手动删！用 'DISM /Online /Cleanup-Image /StartComponentCleanup' 压缩。"

Show-Item "CBS 组件日志" "$env:SystemRoot\Logs\CBS" "A" "Windows 组件服务日志，纯日志。" "可清空旧 .log 文件。"

Show-Item "错误报告 WER" "$env:ProgramData\Microsoft\Windows\WER" "A" "Windows 错误报告队列，纯报错数据。" "可在「磁盘清理」勾选，或清空 ReportQueue/ReportArchive。"

Show-Item "VS 安装缓存 Package Cache" "$env:ProgramData\Package Cache" "B" "Visual Studio 安装包缓存，还在用 VS 则影响修复/改组件。" "不再用 VS 时可清，或移动到其他盘。"

Show-Item "NVIDIA 驱动安装残留" "$env:SystemDrive\NVIDIA" "A" "显卡驱动解压残留，纯临时文件。" "确认驱动装好后可整目录删除。"

Show-Item "AMD 驱动安装残留" "$env:SystemDrive\AMD" "A" "显卡驱动解压残留，纯临时文件。" "确认驱动装好后可整目录删除。"

Show-Item "DirectX 着色器缓存" "$env:LOCALAPPDATA\D3DSCache" "A" "游戏/图形着色器缓存，自动重建。" "可清空，下次运行会重新编译。"

Show-Item "缩略图/图标缓存" "$env:LOCALAPPDATA\Microsoft\Windows\Explorer" "A" "缩略图(thumbcache_*.db)与图标缓存，自动重建。" "可删除，系统会自动重建。"

# ================= 二、用户级缓存 =================

Write-Host ""
Write-Host "================== 二、用户级缓存与临时文件 ==================" -ForegroundColor Cyan

Show-Item "用户临时文件" "$env:TEMP" "A" "系统和应用程序产生的临时文件，可安全清理。"
Show-Item "本地临时文件" "$env:LOCALAPPDATA\Temp" "A" "本地应用程序临时文件，可安全清理。"

$recyclePath = Join-Path $env:SystemDrive '$Recycle.Bin'
Show-Item "回收站" $recyclePath "B" "已删除但可恢复的文件。" "清空前确认里面没有还想找回的文件。"

Show-Item "Chrome 缓存" "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" "A" "Chrome 浏览器缓存，自动重建。"
Show-Item "Edge 缓存" "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache" "A" "Edge 浏览器缓存，自动重建。"
Show-Item "Firefox 缓存" "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles" "A" "Firefox 配置与缓存。"

Show-Item "npm 缓存" "$env:APPDATA\npm-cache" "A" "npm 缓存，'npm cache clean --force' 清理。"
Show-Item "Yarn 缓存" "$env:LOCALAPPDATA\Yarn\Cache" "A" "Yarn 缓存。"
Show-Item "pip 缓存" "$env:LOCALAPPDATA\pip\Cache" "A" "pip 缓存，'pip cache purge' 清理。"
Show-Item "Gradle 缓存" "$env:USERPROFILE\.gradle\caches" "A" "Gradle 构建缓存。"
Show-Item "Maven 缓存" "$env:USERPROFILE\.m2\repository" "B" "Maven 依赖仓库，非垃圾。" "仅在不再用 Java/Maven 时才清。"

# ================= 三、常驻 C 盘的软件数据（建议迁移） =================

Write-Host ""
Write-Host "================== 三、常驻 C 盘的软件数据(建议迁移) ==================" -ForegroundColor Cyan
Write-Host "(这些不是垃圾，但默认塞在 C 盘，是 C 盘悄悄涨大的另一大来源)"

$relocTargets = @(
    @{ Name = "微信聊天记录与文件"; Paths = @("$env:USERPROFILE\Documents\WeChat Files", "$env:USERPROFILE\Documents\xwechat_files"); Tip = "微信 → 设置 → 文件管理 → 更改存储路径到其他盘。" },
    @{ Name = "QQ 聊天记录与文件"; Paths = @("$env:USERPROFILE\Documents\Tencent Files"); Tip = "QQ → 设置 → 文件管理 → 更改个人文件夹位置。" },
    @{ Name = "企业微信文件"; Paths = @("$env:USERPROFILE\Documents\WXWork"); Tip = "企业微信 → 设置 → 存储 → 更改存储位置。" },
    @{ Name = "下载文件夹"; Paths = @("$env:USERPROFILE\Downloads"); Tip = "右键「下载」→ 属性 → 位置 → 移动到其他盘。" },
    @{ Name = "桌面"; Paths = @([Environment]::GetFolderPath('Desktop')); Tip = "桌面文件默认在 C 盘，大文件移走或整体迁移。" },
    @{ Name = "文档"; Paths = @([Environment]::GetFolderPath('MyDocuments')); Tip = "文档默认在 C 盘，可迁移到其他盘。" },
    @{ Name = "图片"; Paths = @([Environment]::GetFolderPath('MyPictures')); Tip = "图片默认在 C 盘，可迁移到其他盘。" },
    @{ Name = "OneDrive"; Paths = @("$env:USERPROFILE\OneDrive"); Tip = "开启「按需下载」或把同步目录迁移到其他盘。" },
    @{ Name = "百度网盘下载"; Paths = @("$env:USERPROFILE\BaiduNetdiskDownload", "$env:USERPROFILE\Documents\BaiduNetdiskDownload"); Tip = "百度网盘 → 设置 → 传输 → 修改下载目录。" },
    @{ Name = "阿里云盘"; Paths = @("$env:USERPROFILE\AliPan", "$env:USERPROFILE\Documents\AliPan"); Tip = "阿里云盘 → 设置 → 修改下载/同步目录。" },
    @{ Name = "Steam 游戏库"; Paths = @("${env:ProgramFiles(x86)}\Steam\steamapps\common", "$env:ProgramFiles\Steam\steamapps\common"); Tip = "Steam → 设置 → 下载 → 添加新的库文件夹到其他盘。" },
    @{ Name = "Epic 游戏"; Paths = @("$env:ProgramFiles\Epic Games"); Tip = "Epic 启动器 → 设置 → 更改安装目录。" }
)

foreach ($t in $relocTargets) {
    foreach ($p in $t.Paths) {
        if ((Test-Path -LiteralPath $p) -and $p.StartsWith($env:SystemDrive, [System.StringComparison]::OrdinalIgnoreCase)) {
            Show-Item $t.Name $p "M" "常驻 C 盘的软件数据，非垃圾，建议迁移。" $t.Tip
            break
        }
    }
}

# ================= 汇总 =================

Write-Host ""
Write-Host "============================================================"
Write-Host "汇总建议："
Write-Host "1. [A 可删] 项目可安全清理，删了会自动重建；但所有删除都需你手动确认，本脚本/助手不自动删。"
Write-Host "2. [B 谨慎] 项目（崩溃转储、Windows.old、还原点、回收站、hiberfil 等）删前务必确认，不自动删。"
Write-Host "3. [C 禁删] 项目（WinSxS、Installer）只能用官方工具(DISM/磁盘清理)处理，绝不手动删。"
Write-Host "4. [M 迁移] 项目是软件数据，按提示迁移到其他盘，从根上遏制 C 盘增长。"
Write-Host "5. 本脚本及助手都不会自动删除任何文件，所有删除操作都需你手动确认。"
Write-Host "============================================================"
