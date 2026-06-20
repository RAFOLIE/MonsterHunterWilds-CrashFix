# MonsterHunterWilds-CrashFix

怪物猎人荒野 (Monster Hunter Wilds) **启动即崩溃** (`EXCEPTION_ILLEGAL_INSTRUCTION`) 一键修复脚本。

适用于 RE Engine 在游戏版本升级后, 因着色器缓存损坏导致的启动崩溃。所有操作**可逆**, 不删除任何文件。

---

## 🩺 解决什么问题

崩溃报告里出现这样的信息:

```
ExceptionCode : C000001D (EXCEPTION_ILLEGAL_INSTRUCTION)
ExceptionAddress: 000000014ADC21DF   (落在游戏主模块内)
Stack[0] : 0x0000000000000000 ( No Module )   ← 调用栈为空
```

**根因**:游戏升级到新版本后,本地的着色器缓存 (`shader.cache2`) / 管线缓存 (`piplinelist.bin`) 仍是旧版本编译产物。新版本游戏加载旧缓存里的机器码时,其中可能包含当前 CPU 不支持的指令,直接抛出非法指令异常而崩溃。

**为什么 Steam "验证文件完整性" 没用**:Steam 只校验游戏自带的文件 (`.exe` / `.pak`),而 `shader.cache2` 是引擎在本机自动生成的,Steam 不会覆盖它。

---

## 🚀 快速使用

### 方法 A:右键 "用 PowerShell 运行"(最简单)
1. 下载本项目(克隆或下载 ZIP)。
2. 在项目文件夹里,右键 `fix.ps1` → "使用 PowerShell 运行"。
3. 脚本会自动查找游戏目录并修复。

### 方法 B:命令行
```powershell
# 自动查找游戏并修复
.\fix.ps1

# 手动指定游戏路径
.\fix.ps1 -GamePath "F:\SteamLibrary\steamapps\common\MonsterHunterWilds"

# 只预演, 不做任何改动
.\fix.ps1 -DryRun
```

> 首次运行若被系统策略拦截,在 PowerShell 里执行一次:
> `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`

---

## 🔧 脚本做了什么

`fix.ps1` 执行 3 步**可逆**操作:

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | 备份 `config.ini` | 生成 `config.ini.bak_yyyyMMdd_HHmmss` |
| 2 | 重命名缓存 | `shader.cache2` → `.bak`、`piplinelist.bin` → `.bak` |
| 3 | 改配置 | `config.ini` 的 `[Render]` 段 `AllowMeshShader=Enable` → `Disable` |

下次启动游戏会重新编译着色器 → 不再加载损坏的旧缓存 → 崩溃消失。

---

## ↩️ 回滚

```powershell
# 只恢复配置 (AllowMeshShader 改回 Enable)
.\restore.ps1

# 连缓存文件名一起恢复 (谨慎: 损坏缓存恢复后可能再次崩溃)
.\restore.ps1 -RestoreCache
```

---

## ⚠️ 注意事项

- 清缓存后**首次启动会明显变慢**(重新编译着色器,1~3 分钟,风扇可能狂转),属正常现象,不是卡死。
- 本脚本只处理"启动崩溃"。若问题依旧,请继续排查:
  - 更新主板 BIOS 微码(尤其 AMD Zen3 CPU)
  - `sfc /scannow` 修复系统文件
  - 关闭 CPU 超频 / 内存 XMP 后测试
  - 用 WinDbg / CrashReport 解析 `MiniDump.dmp` 定位崩溃函数
- `AllowMeshShader=Disable` 是 RE Engine 对 Zen3 + RTX 组合的稳定性兜底。如确认稳定后想开回,可运行 `restore.ps1`。

---

## 📁 文件说明

| 文件 | 作用 |
|------|------|
| `fix.ps1` | 修复主脚本 |
| `restore.ps1` | 回滚脚本 |
| `LICENSE` | MIT |

---

## 📜 免责声明

本脚本不修改游戏本体文件,仅处理引擎生成的本地缓存与配置,且全部可回滚。使用风险自负。Monster Hunter Wilds 版权归 Capcom 所有,本项目与之无关联。
