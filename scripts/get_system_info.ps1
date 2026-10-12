# get_system_info.ps1
# 描述: 获取 Windows 系统配置信息的脚本

Write-Host "================================================"
Write-Host "           系统配置信息概览"
Write-Host "================================================"

# 1. 主机信息
Write-Host "【主机信息】"
Write-Host "  主机名    : $env:COMPUTERNAME"
Write-Host "  用户名    : $env:USERNAME"
Write-Host ""

# 2. 操作系统版本
Write-Host "【操作系统】"
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "  系统名称  : $($os.Caption)"
Write-Host "  系统版本  : $($os.Version) (Build $($os.BuildNumber))"
Write-Host ""

# 3. CPU 信息
Write-Host "【CPU 信息】"
$cpu = Get-CimInstance Win32_Processor
Write-Host "  型号      : $($cpu.Name.Trim())"
Write-Host "  物理核心  : $($cpu.NumberOfCores)"
Write-Host "  逻辑核心  : $($cpu.NumberOfLogicalProcessors)"
Write-Host "  架构      : $($os.OSArchitecture)"
Write-Host ""

# 4. 内存信息
Write-Host "【内存信息】"
$mem = Get-CimInstance Win32_ComputerSystem
$memGB = [math]::Round($mem.TotalPhysicalMemory / 1GB, 2)
Write-Host "  总内存    : $memGB GB"
Write-Host ""

# 5. 磁盘使用情况 (C 盘)
Write-Host "【磁盘信息 (C 盘)】"
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$totalGB = [math]::Round($disk.Size / 1GB, 2)
$freeGB  = [math]::Round($disk.FreeSpace / 1GB, 2)
$usedGB  = [math]::Round($totalGB - $freeGB, 2)
$percent = [math]::Round(($usedGB / $totalGB) * 100, 1)
Write-Host "  总容量    : $totalGB GB"
Write-Host "  已用      : $usedGB GB"
Write-Host "  可用      : $freeGB GB"
Write-Host "  使用率    : $percent%"
Write-Host ""

# 6. 网络信息
Write-Host "【网络信息】"
$ip = (Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' } |
    Select-Object -First 1).IPAddress
if ($ip) {
    Write-Host "  IP 地址   : $ip"
} else {
    Write-Host "  IP 地址   : 未连接或无法获取"
}
Write-Host ""

Write-Host "================================================"
Write-Host "信息获取完成。"
