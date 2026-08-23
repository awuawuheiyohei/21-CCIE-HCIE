# ContainerLab VLAN + Trunk Lab

> **目的**：用真·Linux bridge + 802.1Q VLAN 模拟交换机行为，
> 验证 **VLAN 隔离** 和 **trunk 透传**。
> 这是**你问的 "switch(es)"** 第一个 lab。
>
> **真实度**：⭐⭐⭐⭐ Linux 内核真实 VLAN 行为，跟真交换机一致。

## 拓扑

```
   VLAN 10                                  VLAN 10
  +--------+  eth1     +--------+  eth3    +--------+  eth1     +--------+
  | host1  |-----------|        |----------|        |-----------| host3  |
  +--------+           |        |          |        |           +--------+
                       |  SW1   |  (trunk) |  SW2   |
  +--------+  eth2     |        |  VLAN    |        |  eth2     +--------+
  | host2  |-----------|        |  10, 20  |        |-----------| host4  |
  +--------+           +--------+          +--------+           +--------+
   VLAN 10                                  VLAN 20
```

| 设备 | VLAN | IP |
|------|------|-----|
| host1 | 10 | 10.10.0.11/24 |
| host2 | 10 | 10.10.0.12/24 |
| host3 | 10 | 10.10.0.13/24 (跨 trunk) |
| host4 | **20** | 10.20.0.14/24 |

## 验证目标

| # | 测试 | 预期 |
|---|------|------|
| 1 | host1 ↔ host2 (同 VLAN 10, 同 switch) | ✅ 通 |
| 2 | host1 ↔ host3 (VLAN 10, 跨 trunk) | ✅ 通 |
| 3 | host1 ↔ host4 (VLAN 10 vs VLAN 20) | ❌ **不通**（VLAN 隔离） |
| 4 | host3 ↔ host4 (VLAN 10 vs VLAN 20) | ❌ 不通 |

## 启动

```bash
cd lab/clab/vlan-trunk
sudo clab deploy
```

约 5 秒后所有 bridge / VLAN 配好。

## 验证

```bash
./verify.sh
```

预期：
```
PASS: 9  FAIL: 0
🎉 全部通过！VLAN 隔离 + trunk 透传都正确
```

## 手动操作

```bash
# 进 SW1 看 bridge 状态
docker exec -it clab-ccie-hcie-vlan-trunk-SW1 bash
bridge link show
bridge vlan show

# 看 trunk 上的 VLAN 标签
docker exec clab-ccie-hcie-vlan-trunk-SW1 tcpdump -i eth3 -n -e

# 从 host1 ping host4（应该不通）
docker exec clab-ccie-hcie-vlan-trunk-host1 ping 10.20.0.14
```

## 实现原理

**这个 lab 跟其他 lab 不同**——不用路由软件（FRR），直接用 Linux 内核：

```
┌─────────────────────────────────────┐
│  SW1 容器 (alpine + NET_ADMIN)      │
│                                     │
│  eth1 (host1) ──┐                   │
│  eth2 (host2) ──┼──→ br0 (bridge)   │
│  eth3 (trunk) ──┘                   │
│                                     │
│  br0.10 (VLAN 10 子接口)             │
│  br0.20 (VLAN 20 子接口)             │
│                                     │
│  bridge vlan:                       │
│    eth1: PVID=10 (untagged)         │
│    eth2: PVID=10 (untagged)         │
│    eth3: trunk, 透传 VLAN 10 + 20   │
└─────────────────────────────────────┘
```

- **Access port** (`eth1`/`eth2`)：收到 untagged 帧 → 自动打 PVID tag → 进 bridge
- **Trunk port** (`eth3`)：保留 tag 透传，让对端 SW2 也能识别 VLAN
- **Bridge**：根据 VLAN tag 决定广播域（同 VLAN 才互转）

## 对应真交换机命令

| 行为 | 真交换机（Huawei S5700） | Linux bridge |
|------|--------------------------|--------------|
| 创建 VLAN | `vlan 10` | `ip link add link br0 name br0.10 type vlan id 10` |
| Access port | `port default vlan 10` | `bridge vlan add dev eth1 vid 10 pvid untagged` |
| Trunk port | `port trunk allow-pass vlan 10 20` | `bridge vlan add dev eth3 vid 10` + `bridge vlan add dev eth3 vid 20` |
| 看 VLAN 表 | `display vlan` | `bridge vlan show` |
| 看 MAC 表 | `display mac-address` | `bridge fdb show` |

## 练习

跑通后试：
- 在 SW1 上加 `bridge vlan add dev eth1 vid 20`（让 host1 同时属于 VLAN 10 和 20）—— host1 应该能 ping host4
- 把 host4 改成 VLAN 10（改 `host4_setup.sh`）—— 所有 host 应该互通
- 加一台 SW3（增加 STP 测试）
- 在 trunk port 上加 `bridge vlan del dev eth3 vid 20`（不让 VLAN 20 通过 trunk）—— host3 应该 ping 不通 host4

## 故障排查

### 容器起不来
```bash
docker logs clab-ccie-hcie-vlan-trunk-SW1
```
常见：alpine 缺工具（bridge 命令在 busybox extras 里）。

### VLAN 隔离不生效
```bash
docker exec clab-ccie-hcie-vlan-trunk-SW1 bridge vlan show
# 应该有 VLAN 10 和 VLAN 20 的配置
```

### Trunk 不通
```bash
# 在 SW1 trunk port 抓包看 tag
docker exec clab-ccie-hcie-vlan-trunk-SW1 tcpdump -i eth3 -n -e
# 应该有 802.1Q tag
```

## 进阶扩展

- **VLANIF（华为）vs SVI（Cisco）**——给 VLAN 配 IP，做 L3 互通
- **M-LAG / vPC**——交换机堆叠 / 链路聚合
- **STP / RSTP / MSTP**——防环协议
- **VXLAN / EVPN**——数据中心虚拟化

每个扩展都是新加几行 `bridge vlan` 命令。
