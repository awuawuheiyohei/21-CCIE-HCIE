# eNSP VLAN + Trunk Lab

> 跟 `lab/clab/vlan-trunk` 完全同构（Huawei S5700 真交换机）。

## 拓扑

2 台 S5700 + 4 台 host，VLAN 10/20 + trunk。

## 真实度

⭐⭐⭐⭐⭐ **真 Huawei S5700 镜像**——跟生产环境一致，HCIE 面试实验必考。

## 使用

1. 打开 eNSP
2. 拖 2 台 S5700 + 4 台 PC
3. 连 5 根线：
   - host1 → SW1.GE0/0/1
   - host2 → SW1.GE0/0/2
   - host1 → SW2.GE0/0/1
   - host4 → SW2.GE0/0/2
   - SW1.GE0/0/24 ↔ SW2.GE0/0/24（trunk）
4. 启动所有设备
5. 配 SW1 / SW2（粘 `configs/*.cfg`）
6. 配 host IP（图形界面）：10.10.0.11/24、10.10.0.12/24、10.10.0.13/24、10.20.0.14/24
7. 跑 `verify-commands.md`

## 跟 ContainerLab 端对照

| 维度 | ContainerLab (Linux bridge) | eNSP (S5700) |
|------|------------------------------|---------------|
| 镜像 | alpine + Linux bridge | Huawei S5700 |
| VLAN 实现 | kernel `bridge vlan` | VRP `vlan` |
| 配置命令 | `ip link` + `bridge vlan` | `vlan batch` + `port default vlan` |
| 启动速度 | 5 秒 | 30-60 秒 |
| macOS | ✅ 原生 | ❌ 需 Windows VM |

跑完两边对比，加深理解。

## 故障排查

- **VLAN 不通**：`display vlan` 看 VLAN 表
- **trunk 不通**：`display port trunk` 看允许的 VLAN
- **抓包**：eNSP 工具栏 Capture
