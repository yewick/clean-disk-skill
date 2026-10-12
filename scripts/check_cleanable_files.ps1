# check_cleanable_files.ps1
# 脚本功能：列举 Windows 系统中常见的垃圾文件和可清理内容，并显示占用空间大小。
# 注意：此脚本仅进行扫描和列举，不会删除任何文件。

Write-Host "============================================================"
Write-Host "               Windows 系统可清理垃圾文件扫描               "
Write-Host "============================================================"
Write-Host "正在扫描，请稍候..."
Write-Host ""

# 函数：递归计算目录大小（字节），屏蔽权限错误
function Get-DirSize {
    param([string]$Path)
    if (Test-Path $Path) {
        $sum = (Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum
        if ($null -eq $sum) { $sum = 0 }
        return $sum
    }
    return $null
}

# 函数：字节数格式化
function Format-Size {
    param([double]$Bytes)
    if ($Bytes -ge 1GB) { return ("{0:N2} GB" -f ($Bytes / 1GB)) }
    elseif ($Bytes -ge 1MB) { return ("{0:N2} MB" -f ($Bytes / 1MB)) }
    elseif ($Bytes -ge 1KB) { return ("{0:N2} KB" -f ($Bytes / 1KB)) }
    else { return "$Bytes B" }
}

# 函数：检查并打印目录大小
function Check-DirSize {
    param(
        [string]$Name,
        [string]$Path,
        [string]$Desc
    )
    $sizeBytes = Get-DirSize -Path $Path
    if ($null -ne $sizeBytes) {
        $size = Format-Size -Bytes $sizeBytes
        Write-Host "[$Name]" -ForegroundColor Yellow
        Write-Host "  路径: $Path"
        Write-Host "  大小: $size" -ForegroundColor Red
        Write-Host "  说明: $Desc"
        Write-Host "------------------------------------------------------------"
    }
}

# 1. 用户/系统临时文件
Check-DirSize "用户临时文件" "$env:TEMP" "系统和应用程序产生的临时文件，通常可以安全清理。"
Check-DirSize "本地临时文件" "$env:LOCALAPPDATA\Temp" "本地应用程序临时文件。"

# 2. 回收站
$recyclePath = Join-Path $env:SystemDrive '$Recycle.Bin'
Check-DirSize "回收站" $recyclePath "已删除但未清空的文件。"

# 3. 浏览器缓存
Check-DirSize "Chrome 缓存" "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" "Chrome 浏览器的缓存文件。"
Check-DirSize "Edge 缓存" "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache" "Edge 浏览器的缓存文件。"
Check-DirSize "Firefox 缓存" "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles" "Firefox 浏览器配置与缓存目录。"

# 4. 包管理器缓存
Check-DirSize "npm 缓存" "$env:APPDATA\npm-cache" "npm 包管理器缓存，可通过 'npm cache clean --force' 清理。"
Check-DirSize "Yarn 缓存" "$env:LOCALAPPDATA\Yarn\Cache" "Yarn 包管理器缓存。"
Check-DirSize "pip 缓存" "$env:LOCALAPPDATA\pip\Cache" "pip 包管理器缓存，可通过 'pip cache purge' 清理。"
Check-DirSize "Gradle 缓存" "$env:USERPROFILE\.gradle\caches" "Gradle 构建缓存。"
Check-DirSize "Maven 缓存" "$env:USERPROFILE\.m2\repository" "Maven 仓库，虽然不是垃圾，但如果很久不用，可能占用大量空间。"

# 5. Windows 更新缓存（仅提示，不建议手动删除）
$updateCache = Join-Path $env:SystemRoot "SoftwareDistribution\Download"
if (Test-Path $updateCache) {
    $sizeBytes = Get-DirSize -Path $updateCache
    $size = Format-Size -Bytes $sizeBytes
    Write-Host "[Windows 更新缓存]" -ForegroundColor Yellow
    Write-Host "  路径: $updateCache"
    Write-Host "  大小: $size" -ForegroundColor Red
    Write-Host "  说明: Windows 更新下载的补丁缓存，清理前需先停止 Windows Update 服务（不建议手动删除）。"
    Write-Host "------------------------------------------------------------"
}

# 6. 下载文件夹 (提醒)
Check-DirSize "下载文件夹" "$env:USERPROFILE\Downloads" "下载的文件，通常包含很多不再需要的安装包和临时文件。"

Write-Host ""
Write-Host "============================================================"
Write-Host "建议清理方式："
Write-Host "1. 使用 'Remove-Item -Recurse -Force <路径>' 删除特定目录内容（请务必小心确认路径）。"
Write-Host "2. 对于 npm，使用 'npm cache clean --force'。"
Write-Host "3. 对于 pip，使用 'pip cache purge'。"
Write-Host "4. 可使用系统自带的「磁盘清理」(cleanmgr) 或「存储感知」进行更安全的清理。"
Write-Host "============================================================"
