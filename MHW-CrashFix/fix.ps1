#requires -Version 5.1
<#
.SYNOPSIS
    Monster Hunter Wilds (怪物猎人荒野) 启动崩溃一键修复
.DESCRIPTION
    修复 RE Engine 在游戏版本升级后, 因着色器缓存 (shader.cache2 / piplinelist.bin)
    损坏导致的 EXCEPTION_ILLEGAL_INSTRUCTION 启动崩溃。

    【推荐用法】把 fix.ps1 / fix.bat 放进游戏根目录 (和 MonsterHunterWilds.exe
    同一个文件夹), 双击 fix.bat 即可。脚本默认用自身所在目录作为游戏目录。

    执行以下【可逆】操作:
      1. 备份 config.ini (带时间戳后缀)
      2. 将 shader.cache2 / piplinelist.bin 重命名为 .bak
      3. 将 config.ini 中 [Render] 段的 AllowMeshShader 改为 Disable

    所有操作均不删除任何文件, 可随时用 restore.ps1 回滚。
.PARAMETER GamePath
    游戏根目录 (包含 MonsterHunterWilds.exe 的目录)。
    省略时使用脚本所在目录。仅当不想把脚本放进游戏目录时才需要指定。
.PARAMETER DryRun
    只打印将要执行的操作, 不实际修改。等价于 -WhatIf。
.EXAMPLE
    .\fix.ps1
    放进游戏根目录后直接运行 (或双击 fix.bat)。
.EXAMPLE
    .\fix.ps1 -GamePath "F:\SteamLibrary\steamapps\common\MonsterHunterWilds"
    手动指定游戏路径 (不把脚本放进游戏目录的情况)。
.EXAMPLE
    .\fix.ps1 -DryRun
    预演, 不做任何改动。
.NOTES
    适用环境: Windows 10/11 + PowerShell 5.1 及以上。
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$GamePath,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
if ($DryRun) { $WhatIfPreference = $true }

# ---------------- 输出辅助 ----------------
function Step($m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "    [OK]   $m" -ForegroundColor Green }
function Skip($m) { Write-Host "    [SKIP] $m" -ForegroundColor DarkGray }
function Warn($m) { Write-Host "    [WARN] $m" -ForegroundColor Yellow }
function Info($m) { Write-Host "           $m" -ForegroundColor Gray }
function Err($m)  { Write-Host "    [ERR]  $m" -ForegroundColor Red }

$GameDirName = 'MonsterHunterWilds'
$ExeName     = "$GameDirName.exe"

# ---------------- 定位游戏目录 ----------------
# 本脚本位于 MHW-CrashFix 文件夹内, 玩家把整个文件夹放进游戏根目录。
# 因此游戏根目录在脚本所在目录的【父级】。这里从 $PSScriptRoot 向上逐级查找,
# 找到第一个包含 MonsterHunterWilds.exe 的目录即为游戏根目录。
# 若显式传入 -GamePath, 则以其为准(后路用法)。
Step "定位游戏目录"
if ($GamePath) {
    $gameDir = $GamePath
    Info "使用 -GamePath 指定的路径"
} else {
    $start = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
    $gameDir = $null
    $dir = $start
    # 向上最多查找 5 层, 避免无限循环
    for ($i = 0; $i -lt 5; $i++) {
        if (Test-Path (Join-Path $dir $ExeName)) { $gameDir = $dir; break }
        $parent = Split-Path $dir -Parent
        if (-not $parent -or $parent -eq $dir) { break }   # 到达盘符根
        $dir = $parent
    }

    if (-not $gameDir) {
        Err "未能找到游戏主程序 $ExeName"
        Err "已从脚本所在目录向上查找:"
        Err "    $start"
        Err ""
        Err "请确认整个 MHW-CrashFix 文件夹已放进怪物猎人荒野游戏根目录"
        Err "(即和 MonsterHunterWilds.exe 同一个文件夹的里面)。"
        Err ""
        Err "如不想移动文件夹, 也可手动指定游戏路径:"
        Info '示例: .\fix.ps1 -GamePath "F:\SteamLibrary\steamapps\common\MonsterHunterWilds"'
        exit 1
    }
    if ($gameDir -ne $start) {
        Info "脚本目录: $start"
    }
}
Ok "游戏目录: $gameDir"

# ---------------- 文件存在性检查 ----------------
Step "检查待处理文件"
$configPath   = Join-Path $gameDir 'config.ini'
$shaderCache  = Join-Path $gameDir 'shader.cache2'
$pipeList     = Join-Path $gameDir 'piplinelist.bin'

if (-not (Test-Path $configPath)) {
    Err "未找到 config.ini, 路径可能不正确。"
    exit 1
}
Ok "config.ini 存在"

# ---------------- 步骤 1: 备份 config.ini ----------------
Step "步骤 1/3  备份 config.ini"
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupPath = "$configPath.bak_$stamp"
if ($PSCmdlet.ShouldProcess($configPath, "备份为 $backupPath")) {
    Copy-Item -LiteralPath $configPath -Destination $backupPath -Force
    Ok "已备份 -> $backupPath"
} else {
    Info "(预演) 将备份 -> $backupPath"
}

# ---------------- 步骤 2: 重命名缓存为 .bak ----------------
Step "步骤 2/3  清理着色器 / 管线缓存"
foreach ($pair in @(
    @{ Src = $shaderCache; Name = 'shader.cache2' },
    @{ Src = $pipeList;    Name = 'piplinelist.bin' }
)) {
    $src  = $pair.Src
    $dest = "$src.bak"
    if (-not (Test-Path $src)) {
        Skip "$($pair.Name) 不存在 (可能已清理过), 跳过"
        continue
    }
    if (Test-Path $dest) {
        Warn "$dest 已存在, 为避免覆盖已改为时间戳后缀"
        $dest = "$src.bak_$stamp"
    }
    if ($PSCmdlet.ShouldProcess($src, "重命名为 $dest")) {
        Move-Item -LiteralPath $src -Destination $dest -Force
        Ok "$($pair.Name) -> $(Split-Path $dest -Leaf)"
    } else {
        Info "(预演) $($pair.Name) -> $(Split-Path $dest -Leaf)"
    }
}

# ---------------- 步骤 3: 修改 config.ini ----------------
Step "步骤 3/3  关闭 Mesh Shader (AllowMeshShader=Disable)"

function Get-AllowMeshShader {
    param([string]$Path)
    $enc = New-Object System.Text.UTF8Encoding($false)
    $content = [System.IO.File]::ReadAllText($Path, $enc)
    $m = [regex]::Match($content, '(?s)\[Render\][^\[]*?AllowMeshShader=(\w+)')
    if ($m.Success) { return $m.Groups[1].Value } else { return $null }
}

function Set-AllowMeshShader {
    param([string]$Path, [string]$NewValue)
    $enc = New-Object System.Text.UTF8Encoding($false)
    $content = [System.IO.File]::ReadAllText($Path, $enc)
    $pattern = '(\[Render\][^\[]*?AllowMeshShader=)\w+'
    if ($content -notmatch $pattern) { return $false }
    $replacement = '${1}' + $NewValue
    $newContent = [regex]::Replace($content, $pattern, $replacement, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($newContent -eq $content) { return $false }
    [System.IO.File]::WriteAllText($Path, $newContent, $enc)
    return $true
}

$current = Get-AllowMeshShader -Path $configPath
if ($null -eq $current) {
    Warn "config.ini [Render] 段未找到 AllowMeshShader 键, 跳过修改。"
} elseif ($current -eq 'Disable') {
    Skip "AllowMeshShader 已是 Disable, 无需修改"
} else {
    if ($PSCmdlet.ShouldProcess($configPath, "AllowMeshShader: $current -> Disable")) {
        $ok = Set-AllowMeshShader -Path $configPath -NewValue 'Disable'
        if ($ok) { Ok "AllowMeshShader: $current -> Disable" } else { Warn "修改未生效, 请手动检查" }
    } else {
        Info "(预演) AllowMeshShader: $current -> Disable"
    }
}

# ---------------- 完成 ----------------
Step "完成"
Ok "修复操作已全部执行。"
Write-Host ""
Write-Host "    下一步: 启动游戏测试。" -ForegroundColor White
Write-Host "    注意: 首次启动因重新编译着色器会明显变慢 (1~3 分钟), 属正常现象。" -ForegroundColor Yellow
Write-Host ""
Write-Host "    如需回滚: " -ForegroundColor White -NoNewline
Write-Host ".\restore.bat" -ForegroundColor Magenta
Write-Host ""

# 双击 .bat 运行时, 窗口不会一闪而过
if ($Host.Name -eq 'ConsoleHost') {
    Write-Host "按回车键退出..." -ForegroundColor DarkGray -NoNewline
    Read-Host | Out-Null
}
