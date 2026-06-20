@echo off
REM ============================================================
REM  Monster Hunter Wilds 启动崩溃修复 - 启动器
REM  把本文件和 fix.ps1 一起放进游戏根目录, 双击即可运行。
REM ============================================================
chcp 65001 >nul
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fix.ps1" %*
echo.
pause
