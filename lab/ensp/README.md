# eNSP OSPF 多区域 Lab

> **目的**：用 Huawei eNSP 模拟器（真 AR2240 镜像）跑 OSPF 多区域 + ABR，
> 跟 `exams/HCIE-RS/lab/2024-08-ospf-multi-area.md` 题目**完全同构**。
>
> **真实度**：⭐⭐⭐⭐ 真 Huawei VRP 系统，支持所有 HCIE 实验。

## 前置要求

| 软件 | 说明 |
|------|------|
| **eNSP** | Huawei 官方网络模拟器，[下载](https://support.huawei.com/enterprise/zh/network-planning/ensp-pid-21323687) |
| **VirtualBox** | eNSP 底层 VM（安装 eNSP 时会自动提示） |
| **WinPcap** | eNSP 抓包用（同上） |
| **PC 操作** | 建议在 Windows 或 macOS 装 eNSP 客户端 |

> 💡 **macOS 用户**：eNSP 官方只支持 Windows。在 macOS 上跑需要装 Parallels / VMware 虚拟机，再在虚拟机里装 Windows + eNSP。

## 拓扑

```
   [Area 0]                    [Area 1]
[R1 AR2240] --10.0.12.0/30-- [R2 AR2240] --10.0.23.0/30-- [R3 AR2240] --10.0.34.0/30-- [PC1]
              GE0/0/0          (ABR)        GE0/0/1          GE0/0/1
```

跟 `lab/clab/`（ContainerLab 版本）**完全同构**——你可以两边对照练习：
- `lab/clab/` 用 FRRouting（Cisco 风格）
- `lab/ensp/` 用 Huawei AR2240（VRP 风格）

## 使用步骤

### 1. 打开 eNSP，按 `topology.md` 搭建

主要工作：
- 拖 3 台 AR2240 + 1 台 PC
- 连 3 根 Copper 线
- 启动所有设备

### 2. 复制粘贴配置

每台设备的配置在 `configs/` 目录：
- `R1.cfg` → R1 的 CLI
- `R2.cfg` → R2 的 CLI
- `R3.cfg` → R3 的 CLI
- PC1 图形化配置：IP 10.0.34.4/24, GW 10.0.34.3

### 3. 等待 OSPF 收敛

启动设备后约 **15-30 秒** OSPF 收敛（华为设备比 FRR 慢一点）。

### 4. 验证

参考 `verify-commands.md` 逐条跑命令。

期望：
- R1 看到 1 个邻居（R2）
- R2 看到 2 个邻居（R1 + R3）
- R3 看到 1 个邻居（R2）
- R1 路由表里能看到 3.3.3.3（跨区域）
- PC1 能 ping 通 1.1.1.1（端到端）

## 与 ContainerLab 版的对比

| 维度 | eNSP（这） | ContainerLab |
|------|-----------|--------------|
| 镜像 | Huawei AR2240（专有） | FRRouting（开源） |
| 命令风格 | Huawei VRP | Cisco IOS（vtysh） |
| 启动速度 | 慢（30-60s） | 快（5-10s） |
| 依赖 | VirtualBox + eNSP | Docker + ContainerLab |
| 真协议 | ✅ 是 | ✅ 是 |
| 资源占用 | 中（VM 占用） | 低（容器） |
| macOS 支持 | ⚠️ 需 VM | ✅ 原生 |
| 适合 | HCIE 真·实验 | 协议行为 + 跨平台 |

## 故障排查

### 设备启动失败
- 检查 VirtualBox 是否装好
- 检查 eNSP 是否能识别 VirtualBox
- 重启 eNSP / 重启电脑

### 邻居建立慢
- 正常现象，华为设备 OSPF 启动慢（dead interval 40s）
- 看到 R1.R2 状态从 Loading 慢慢变 Full，正常

### 配置不生效
- 确认是在系统视图（`<R1>`）而不是用户视图（`<R1>`）
- 确认 `<R1>system-view` 进入
- 用 `display current-configuration` 看实际生效的配置

### 抓包工具
- eNSP 工具栏 → "Capture" → 选中要抓的链路 → Start
- 可以看到 OSPF 5 种报文（Hello / DD / LSR / LSU / LSAck）

## 进阶：扩展

- **BGP**：R3 起 BGP，跟外部 AS 对接（HCIE RS 必考）
- **IS-IS**：替代 OSPF（HCIE RS / SP 方向都考）
- **MPLS**：LDP / MPLS VPN（运营商方向）
- **Stack / M-LAG**：交换机特性（HCIE Datacom）
- **VXLAN / EVPN**：数据中心方向

每个扩展都新写一个 `topology.md` + 一组 cfg 即可。

## 文件清单

```
lab/ensp/
├── README.md              ← 你正在看
├── topology.md            ← 拓扑描述（手动在 eNSP 里搭建）
├── configs/
│   ├── R1.cfg             ← 复制粘到 R1 的 CLI
│   ├── R2.cfg             ← 复制粘到 R2 的 CLI
│   └── R3.cfg             ← 复制粘到 R3 的 CLI
└── verify-commands.md     ← 验证命令清单
```
