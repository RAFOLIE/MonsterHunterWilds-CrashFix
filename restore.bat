@echo off
REM ============================================================
REM  Monster Hunter Wilds 修复回滚 - 启动器
REM  把本文件和 restore.ps1 一起放进游戏根目录, 双击即可运行。
REM ============================================================
chcp 65001 >nul
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore.ps1" %*
echo.
pause
