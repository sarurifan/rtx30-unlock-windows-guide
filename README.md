# RTX 30系 Windows 自动解锁实战指南（3080 20G 实测）

> 实测机器：联想刃7000（锐龙5800，无核显） + RTX 3080 20G 魔改卡
> 实测成绩：FP16 GEMM 4096³ **54.6 → 106.36 TFLOPS**（解锁翻倍）
> 状态：显存 10240 → **20480 MiB**，满载 100% util / 318W / 53°C，功耗墙未放宽

## ⚠️ 慎重声明

本方案要动**硬盘分区 + UEFI 启动项**，做不好会系统起不来。
**没有系统救援能力（会进 WinPE、会修引导、数据有备份）的，强烈建议用 U盘方案，不要碰自动方案。**

实测全程开关机十几轮（探测冷启动2次、注册恢复6轮、WinPE救援数次），翻车截图如下——diskpart 查分区、bcdedit 修启动项。

## 两种方案对比

| | U盘方案 | 自动方案（本文实测） |
|---|---|---|
| 原理 | 插U盘引导解锁，每次开机手动 | 解锁器装硬盘隐藏分区+UEFI启动项，开机自动 |
| 稳定性 | 高，系统基本不受影响 | 中，动分区和引导 |
| 安全性 | 高 | 中，需要救援能力 |
| 便利性 | 每次插U盘 | 无感，开机自动解锁 |
| 主板兼容 | 对固件要求简单 | **一机一档案**，华硕B650M/B660M有官方档案；联想刃7000固件拓扑特殊需自造 |

**结论：能接受插U盘就选U盘方案（稳定安全）；想要无感自动就选自动方案，但先确认主板兼容 + 自己有救援能力。**

## 仓库地址

- 自动方案（无U盘）：https://github.com/impacifist/Windows-GPU-UNLOCK
- U盘方案：https://github.com/Siselea/rtx30-unlock-windows-toolkit

## 自动方案五步流程

前置：Windows 装好 **git + clang + bun**。

### 1. 克隆仓库
```powershell
git clone https://github.com/impacifist/Windows-GPU-UNLOCK
```

### 2. 编译只读探测 EFI（零写入）
```powershell
pwsh scripts/build-probe.ps1
```
装进硬盘分区，**冷启动两次**采集指纹（机器自动写 PROFILE.BIN）。

### 3. 生成机器档案（一机一档）
```powershell
pwsh research/profile/make-profile.py
```
> 联想刃7000 这类固件拓扑特殊的机器：官方档案不匹配，需要改源码（probe.c 设备白名单加 0x220610de、GU_PROBE_BUS=0x7、proven.json 放宽）后重编译，详见实测笔记。

### 4. 构建 + 注册开机自启
```powershell
pwsh internal-boot/build-unlock.ps1
pwsh internal-boot/Headless.ps1 -Register
```
自动建隐藏 FAT32 分区 + 注册 UEFI 启动项，开机自动解锁自动回 Windows。

### 5. 验证
```cmd
nvidia-smi
```
显存 10240 → **20480 MiB** 即解锁生效；跑分翻倍（FP16 54.6 → 106.36）。

## 还原

```powershell
pwsh internal-boot/Headless.ps1 -RestoreWindowsFirst
```
或回滚备份：`C:\ProgramData\WindowsGPUUnlock\HeadlessBackups\`（含 firmware-before/after 记录）。

## 实测数据

| 指标 | 锁定 | 解锁 |
|---|---|---|
| FP16 GEMM 4096³ | 54.6 TFLOPS | **106.36 TFLOPS** |
| BF16 | 53.0 | 106.37 |
| FP32 | 21.9 | 21.95（不动，佐证只解锁Tensor Core） |
| 满载 util | 100% | 100% |
| 功耗 | ~318W | ~318W（贴墙不越墙，≤320W） |
| 温度 | 56°C | 53°C |

重启后自动解锁验证：无人值守重启 → 自动跑解锁器 → 回 Windows → 106.36 满血。

## 实测笔记（联想刃7000 专属坑）

- 联想固件 GOP 拓扑不合规，Siselea 版直接 EFI_ACCESS_DENIED 拒跑（GcLeafPair 要求 1 持有者+1 子设备）
- 自动方案探测：`GU_PROBE_BUS=0x7U`（卡在 bus 7）、设备白名单加 0x220610de、proven.json 显存列表加 0x5000
- 探测版日志目录必须预建：`mkdir F:\RTX3090-UNLOCK`，否则 prepare-failed EFI_DEVICE_ERROR
- 每次启动覆盖写 PROM.BIN/IMGnn.BIN，采集多次要手动归档
- 冷启动产物：AUTO%06d/REPORT.TXT（headless 执行日志）、DIAGnn.TXT（探测日志）
- 成功判据：REPORT.TXT 尾部 `SS0=88888888 SS1=00000008` + `transaction result=0 containment=0` + WPR2 写保护已上

## 产物共用性（同款联想机器）

自动方案的档案（PROFILE.BIN / machine-profile 常量）绑定：PCI/子系统 ID、BAR0/根端口、驱动指纹、**PROM SHA256（每张卡 vBIOS 内容哈希）**。

- 同型号主板 + 同型号卡 + **同一家刷的 BIOS（PROM 哈希一致）** → 产物可共用
- PROM 哈希不同 → 档案校验安全拒跑（不碰硬件，不会损坏），需重新采集
- 探测阶段零写入，同款机器各跑两次冷启动最稳（几分钟）

