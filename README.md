# MonsterHunterWilds-CrashFix

怪物猎人荒野 (Monster Hunter Wilds) **启动即崩溃** (`EXCEPTION_ILLEGAL_INSTRUCTION`) 一键修复工具。

适用于 RE Engine 在游戏版本升级后, 因着色器缓存损坏导致的启动崩溃。所有操作**可逆**, 不删除任何文件。

---

## 🚀 使用方法 (2 步)

### 第 1 步:把整个文件夹放进游戏根目录

把仓库里的 **`MHW-CrashFix` 文件夹整个**复制进怪物猎人荒野游戏根目录(也就是 `MonsterHunterWilds.exe` 所在的文件夹)。

```
...\steamapps\common\MonsterHunterWilds\      ← 游戏根目录
├── MonsterHunterWilds.exe
├── config.ini
├── shader.cache2
└── MHW-CrashFix\          ← 把整个文件夹放进来 👈
    ├── fix.bat            ← 双击这个修复
    ├── fix.ps1
    ├── restore.bat        ← 双击这个回滚
    ├── restore.ps1
    └── README.txt
```

> 不知道游戏在哪?Steam 库 → 右键 Monster Hunter Wilds → 管理 → 浏览本地文件。

### 第 2 步:双击 `MHW-CrashFix\fix.bat`

会弹出一个黑色窗口,自动完成修复。看到 `[OK] 修复操作已全部执行` 就成功了。

> 脚本会自动从所在文件夹**向上查找**游戏根目录,所以文件夹放在游戏根目录里就能用。放错了会提示找不到游戏并退出,不会误操作。

**用完想清理?** 直接删掉 `MHW-CrashFix` 文件夹即可,一个文件夹搞定,不用一个个找文件。当然留着也不碍事。

---

## ↩️ 回滚

双击 `MHW-CrashFix\restore.bat` 即可。

---

## 🩺 解决什么问题

崩溃报告里出现:

```
ExceptionCode : C000001D (EXCEPTION_ILLEGAL_INSTRUCTION)
ExceptionAddress: 000000014ADC21DF   (落在游戏主模块内)
Stack[0] : 0x0000000000000000 ( No Module )   ← 调用栈为空
```

**根因**:游戏升级后,本地着色器缓存 (`shader.cache2`) / 管线缓存 (`piplinelist.bin`) 仍是旧版本编译产物,新版本游戏加载时遇到当前 CPU 不支持的指令而崩溃。

**为什么 Steam "验证文件完整性" 没用**:Steam 只校验游戏自带文件 (`.exe` / `.pak`),`shader.cache2` 是引擎在本机生成的,Steam 不覆盖它。

`fix.bat` 执行 3 步**可逆**操作:备份 `config.ini` → 重命名缓存为 `.bak` → 设置 `AllowMeshShader=Disable`。

---

## ⚠️ 注意事项

- 清缓存后**首次启动会明显变慢**(重新编译着色器,1~3 分钟),属正常现象。
- 本工具只处理"启动崩溃"。若问题依旧,继续排查:更新主板 BIOS 微码、`sfc /scannow`、关闭超频、解析 `MiniDump.dmp`。
- 不想用文件夹方式?也可用 `-GamePath` 参数手动指定:
  ```
  powershell -NoProfile -ExecutionPolicy Bypass -File "...\MHW-CrashFix\fix.ps1" -GamePath "F:\SteamLibrary\steamapps\common\MonsterHunterWilds"
  ```

---

## 📜 免责声明

本工具不修改游戏本体文件,仅处理引擎生成的本地缓存与配置,且全部可回滚。使用风险自负。Monster Hunter Wilds 版权归 Capcom 所有,本项目与之无关联。
