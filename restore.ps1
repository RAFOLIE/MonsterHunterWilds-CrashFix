#requires -Version 5.1
<#
.SYNOPSIS
    回滚 fix.ps1 对怪物猎人荒野所做的修改
.DESCRIPTION
    将 config.ini 中 [Render] 段的 AllowMeshShader 改回 Enable。
    使用 -RestoreCache 可同时把 shader.cache2.bak / piplinelist.bin.bak 恢复原名。

    【推荐用法】和 fix.ps1 一样, 把 restore.ps1 / restore.bat 放进游戏根目录,
    双击 restore.bat 即可。脚本默认用自身所在目录作为游戏目录。
.PARAMETER GamePath
    游戏根目录 (包含 MonsterHunterWilds.exe 的目录)。
    省略时使用脚本所在目录。
.PARAMETER RestoreCache
    同时恢复缓存文件 (.bak -> 原名)。注意: 损坏的缓存恢复后可能再次崩溃。
.PARAMETER DryRun
    只打印将执行的操作, 不实际修改。
.EXAMPLE
    .\restore.ps1
    放进游戏根目录后直接运行 (或双击 restore.bat)。
.EXAMPLE
    .\restore.ps1 -RestoreCache
    同时恢复缓存文件名。
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$GamePath,
    [switch]$RestoreCache,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
if ($DryRun) { $WhatIfPreference = $true }

function Step($m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function Ok($m)   { Write-Host "    [OK]   $m" -ForegroundColor Green }
function Skip($m) { Write-Host "    [SKIP] $m" -ForegroundColor DarkGray }
function Warn($m) { Write-Host "    [WARN] $m" -ForegroundColor Yellow }
function Info($m) { Write-Host "           $m" -ForegroundColor Gray }
function Err($m)  { Write-Host "    [ERR]  $m" -ForegroundColor Red }

$GameDirName = 'MonsterHunterWilds'
$ExeName     = "$GameDirName.exe"

# ---------------- 定位游戏目录 ----------------
# 默认使用脚本自身所在目录($PSScriptRoot), 即把本脚本放进游戏根目录后双击即可。
# 若显式传入 -GamePath, 则以其为准(后路用法)。
Step "定位游戏目录"
if ($GamePath) {
    $gameDir = $GamePath
    Info "使用 -GamePath 指定的路径"
} elseif ($PSScriptRoot) {
    $gameDir = $PSScriptRoot
} else {
    $gameDir = (Get-Location).Path
    Warn "未获取到脚本所在目录, 改用当前工作目录: $gameDir"
}

# 安全校验: 目录里必须存在游戏主程序, 否则报错退出
if (-not (Test-Path (Join-Path $gameDir $ExeName))) {
    Err "在以下目录中未找到 $ExeName :"
    Err "    $gameDir"
    Err ""
    Err "请把本脚本(restore.ps1 / restore.bat)放到怪物猎人荒野游戏根目录"
    Err "(即和 MonsterHunterWilds.exe 同一个文件夹)后再运行。"
    Err ""
    Err "如不想把脚本复制进游戏目录, 也可手动指定路径:"
    Info '示例: .\restore.ps1 -GamePath "F:\SteamLibrary\steamapps\common\MonsterHunterWilds"'
    exit 1
}
Ok "游戏目录: $gameDir"

$configPath = Join-Path $gameDir 'config.ini'

# ---- 恢复 AllowMeshShader=Enable ----
Step "恢复 AllowMeshShader = Enable"
function Set-AllowMeshShader {
    param([string]$Path, [string]$NewValue)
    $enc = New-Object System.Text.UTF8Encoding($false)
    $content = [System.IO.File]::ReadAllText($Path, $enc)
    $pattern = '(\[Render\][^\[]*?AllowMeshShader=)\w+'
    if ($content -notmatch $pattern) { return @{ Changed = $false; Reason = 'KeyNotFound' } }
    $cur = ([regex]::Match($content, '(?s)\[Render\][^\[]*?AllowMeshShader=(\w+')).Groups[1].Value
    if ($cur -eq $NewValue) { return @{ Changed = $false; Reason = 'AlreadySet'; Current = $cur } }
    $replacement = '${1}' + $NewValue
    $newContent = [regex]::Replace($content, $pattern, $replacement, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($newContent -eq $content) { return @{ Changed = $false; Reason = 'NoChange' } }
    [System.IO.File]::WriteAllText($Path, $newContent, $enc)
    return @{ Changed = $true; Old = $cur; New = $NewValue }
}

if (Test-Path $configPath) {
    if ($PSCmdlet.ShouldProcess($configPath, "AllowMeshShader -> Enable")) {
        $r = Set-AllowMeshShader -Path $configPath -NewValue 'Enable'
        switch ($r.Reason) {
            'KeyNotFound'  { Warn "[Render] 段未找到 AllowMeshShader" }
            'AlreadySet'   { Skip "AllowMeshShader 已是 $($r.Current)" }
            default        { if ($r.Changed) { Ok "AllowMeshShader: $($r.Old) -> $($r.New)" } else { Warn "修改未生效" } }
        }
    } else { Info "(预演) AllowMeshShader -> Enable" }
} else { Warn "config.ini 不存在, 跳过" }

# ---- 可选: 恢复缓存文件名 ----
if ($RestoreCache) {
    Step "恢复缓存文件名 (.bak -> 原名)"
    foreach ($pair in @(
        @{ Bak = (Join-Path $gameDir 'shader.cache2.bak');    Name = 'shader.cache2.bak' },
        @{ Bak = (Join-Path $gameDir 'piplinelist.bin.bak');  Name = 'piplinelist.bin.bak' }
    )) {
        $bak = $pair.Bak
        $orig = $bak -replace '\.bak$',''
        if (-not (Test-Path $bak)) { Skip "$($pair.Name) 不存在"; continue }
        if (Test-Path $orig) { Warn "$(Split-Path $orig -Leaf) 已存在, 跳过恢复"; continue }
        if ($PSCmdlet.ShouldProcess($bak, "恢复为 $(Split-Path $orig -Leaf)")) {
            Move-Item -LiteralPath $bak -Destination $orig -Force
            Ok "$($pair.Name) -> $(Split-Path $orig -Leaf)"
        } else { Info "(预演) $($pair.Name) -> $(Split-Path $orig -Leaf)" }
    }
    Warn "注意: 恢复损坏的缓存可能导致再次崩溃, 仅在排查需要时使用。"
} else {
    Step "缓存文件"
    Info "未指定 -RestoreCache, 缓存 .bak 文件保持不变。"
    Info "如需恢复缓存文件名: 双击 restore.bat -RestoreCache  或  .\restore.ps1 -RestoreCache"
}

Step "回滚完成"

# 双击 .bat 运行时, 窗口不会一闪而过
if ($Host.Name -eq 'ConsoleHost') {
    Write-Host ""
    Write-Host "按回车键退出..." -ForegroundColor DarkGray -NoNewline
    Read-Host | Out-Null
}
