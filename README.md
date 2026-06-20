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

## 🚀 使用方法 (3 步)

### 第 1 步:找到游戏根目录

也就是 **`MonsterHunterWilds.exe` 所在的文件夹**。常见路径:

```
C:\Program Files (x86)\Steam\steamapps\common\MonsterHunterWilds\
D:\SteamLibrary\steamapps\common\MonsterHunterWilds\
E:\SteamLibrary\steamapps\common\MonsterHunterWilds\
```

> 不知道在哪?Steam 库 → 右键 Monster Hunter Wilds → 管理 → 浏览本地文件。

### 第 2 步:把脚本放进去

把以下 **4 个文件** 一起复制进游戏根目录(和 `MonsterHunterWilds.exe` 同一个文件夹):

- `fix.ps1` + `fix.bat`
- `restore.ps1` + `restore.bat`

```
...\MonsterHunterWilds\
    ├── MonsterHunterWilds.exe      ← 游戏本体
    ├── config.ini
    ├── shader.cache2
    ├── fix.ps1         ← 放这里 👈
    ├── fix.bat         ← 放这里 👈
    ├── restore.ps1     ← 放这里 👈
    └── restore.bat     ← 放这里 👈
```

### 第 3 步:双击 `fix.bat`

会弹出一个黑色窗口,自动完成修复。看到 `[OK] 修复操作已全部执行` 就成功了。

> 💡 脚本默认用**自己所在的目录**作为游戏目录,所以一定要放进游戏根目录。放错了会提示找不到 `MonsterHunterWilds.exe` 并退出,不会瞎搞。

---

## 🔧 脚本做了什么

`fix.bat` / `fix.ps1` 执行 3 步**可逆**操作:

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | 备份 `config.ini` | 生成 `config.ini.bak_yyyyMMdd_HHmmss` |
| 2 | 重命名缓存 | `shader.cache2` → `.bak`、`piplinelist.bin` → `.bak` |
| 3 | 改配置 | `config.ini` 的 `[Render]` 段 `AllowMeshShader=Enable` → `Disable` |

下次启动游戏会重新编译着色器 → 不再加载损坏的旧缓存 → 崩溃消失。

---

## ↩️ 回滚

双击 `restore.bat` 即可恢复。或用命令行:

```powershell
# 只恢复配置 (AllowMeshShader 改回 Enable)
.\restore.ps1

# 连缓存文件名一起恢复 (谨慎: 损坏缓存恢复后可能再次崩溃)
.\restore.ps1 -RestoreCache
```

---

## ⚙️ 进阶:不想把脚本放进游戏目录?

如果你不想把脚本复制进游戏目录,可以直接用 `-GamePath` 参数指定路径:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\放脚本的目录\fix.ps1" -GamePath "F:\SteamLibrary\steamapps\common\MonsterHunterWilds"
```

或预演 (不改动任何文件):

```powershell
.\fix.ps1 -DryRun
```

---

## ⚠️ 注意事项

- 清缓存后**首次启动会明显变慢**(重新编译着色器,1~3 分钟,风扇可能狂转),属正常现象,不是卡死。
- 本脚本只处理"启动崩溃"。若问题依旧,请继续排查:
  - 更新主板 BIOS 微码(尤其 AMD Zen3 CPU)
  - `sfc /scannow` 修复系统文件
  - 关闭 CPU 超频 / 内存 XMP 后测试
  - 用 WinDbg / CrashReport 解析 `MiniDump.dmp` 定位崩溃函数
- `AllowMeshShader=Disable` 是 RE Engine 对 Zen3 + RTX 组合的稳定性兜底。如确认稳定后想开回,可运行 `restore.bat`。

---

## 📁 文件说明

| 文件 | 作用 |
|------|------|
| `fix.bat` | 修复启动器,**双击运行** |
| `fix.ps1` | 修复主脚本 (被 .bat 调用) |
| `restore.bat` | 回滚启动器,**双击运行** |
| `restore.ps1` | 回滚脚本 (被 .bat 调用) |
| `LICENSE` | MIT |

---

## 📜 免责声明

本脚本不修改游戏本体文件,仅处理引擎生成的本地缓存与配置,且全部可回滚。使用风险自负。Monster Hunter Wilds 版权归 Capcom 所有,本项目与之无关联。
