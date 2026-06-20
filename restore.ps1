#requires -Version 5.1
<#
.SYNOPSIS
    回滚 fix.ps1 对怪物猎人荒野所做的修改
.DESCRIPTION
    将 config.ini 中 [Render] 段的 AllowMeshShader 改回 Enable。
    使用 -RestoreCache 可同时把 shader.cache2.bak / piplinelist.bin.bak 恢复原名。
.PARAMETER GamePath
    游戏根目录。省略时自动搜索。
.PARAMETER RestoreCache
    同时恢复缓存文件 (.bak -> 原名)。注意: 损坏的缓存恢复后可能再次崩溃。
.PARAMETER DryRun
    只打印将执行的操作, 不实际修改。
.EXAMPLE
    .\restore.ps1
    仅恢复 AllowMeshShader=Enable。
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

function Find-LibraryFolders {
    $found = New-Object System.Collections.Generic.List[string]
    $steamRoots = @("$env:ProgramFiles(x86)\Steam", "${env:ProgramFiles}\Steam", "C:\Program Files (x86)\Steam")
    foreach ($d in @('C','D','E','F','G','H','I')) {
        $steamRoots += "${d}:\Steam"; $steamRoots += "${d}:\SteamLibrary"
    }
    $steamRoots = $steamRoots | Where-Object { $_ } | Select-Object -Unique
    foreach ($root in $steamRoots) {
        if (-not (Test-Path $root)) { continue }
        if (-not $found.Contains($root)) { $found.Add($root) | Out-Null }
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (Test-Path $vdf) {
            foreach ($line in Get-Content $vdf -ErrorAction SilentlyContinue) {
                if ($line -match '"path"\s+"(.+)"') {
                    $p = $matches[1] -replace '\\\\', '\'
                    if ((Test-Path $p) -and -not $found.Contains($p)) { $found.Add($p) | Out-Null }
                }
            }
        }
    }
    return $found
}
function Find-GameDir {
    foreach ($lib in (Find-LibraryFolders)) {
        $candidate = Join-Path $lib "steamapps\common\$GameDirName"
        if (Test-Path (Join-Path $candidate $ExeName)) { return $candidate }
    }
    return $null
}

Step "定位游戏目录"
if ($GamePath) {
    if (-not (Test-Path (Join-Path $GamePath $ExeName))) { Err "指定路径下未找到 $ExeName"; exit 1 }
    $gameDir = $GamePath
} else {
    $gameDir = Find-GameDir
    if (-not $gameDir) { Err "未能自动找到游戏目录, 请用 -GamePath 指定"; exit 1 }
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
    Info "如需恢复缓存文件名: .\restore.ps1 -RestoreCache"
}

Step "回滚完成"
