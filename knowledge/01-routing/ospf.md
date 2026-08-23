# OSPF（Open Shortest Path First）

> 链路状态路由协议，使用 **Dijkstra SPF 算法** 计算最短路径。
> IGP 标杆，CCIE / HCIE 必考。

## 1. 原理

### 1.1 核心机制

- **Router ID**：32 位唯一标识，手工配置优选，否则用最大 Loopback IP
- **Area**：分层设计，Area 0 是骨干，所有非骨干区域必须与 Area 0 直连
- **LSA（Link-State Advertisement）**：链路状态信息单元
- **LSDB**：链路状态数据库，全网同步
- **SPF 算法**：以自己为根计算到所有网络的最短路径树

### 1.2 邻居状态机

```
Down → Init → 2-Way → Exstart → Exchange → Loading → Full
```

| 状态 | 含义 |
|------|------|
| Down | 初始，未收到任何包 |
| Init | 收到对端 Hello，但对方没看到自己 |
| 2-Way | 双向通信建立（MA 网络中 DR/BDR 在此选举） |
| Exstart | 协商 Master/Slave，交换 DD 序列号 |
| Exchange | 交换 DD 摘要 |
| Loading | 交换 LSR / LSU |
| Full | LSDB 完全同步 |

### 1.3 LSA 类型

| Type | 名称 | 生成者 | 范围 | 内容 |
|------|------|--------|------|------|
| 1 | Router LSA | 所有路由器 | 本区域 | 链路状态 + 拓扑 |
| 2 | Network LSA | DR | 本区域 | MA 网络的伪节点 + 拓扑 |
| 3 | Summary LSA | ABR | 区域间 | 区域间路由 |
| 4 | ASBR Summary LSA | ABR | 除 ASBR 所在区域 | ASBR 位置 |
| 5 | AS External LSA | ASBR | 整个 AS | 外部路由 |
| 7 | NSSA External LSA | ASBR（NSSA 区域） | NSSA 区域 | NSSA 外部路由，ABR 转 5 类 |

---

## 2. 华为实现（NE / AR / CE 系列）

### 2.1 基础配置

```bash
# 全局启用 OSPF
ospf 1 router-id 1.1.1.1
 area 0.0.0.0
  network 10.1.1.0 0.0.0.255
 area 0.0.0.1
  network 10.2.1.0 0.0.0.255
```

### 2.2 关键特性

- **区域 ID 支持点分十进制**：`area 0.0.0.0` 或 `area 0` 都行
- **接口开销**：默认根据带宽自动计算，可手工 `ospf cost <value>`
- **DR 优先级**：`ospf dr-priority <0-255>`，0 表示不参与选举
- **认证**：`ospf authentication-mode md5 1 cipher <key>`

### 2.3 常用维护命令

```bash
display ospf peer brief          # 查看邻居
display ospf lsdb               # 查看 LSDB
display ospf routing             # 查看 OSPF 路由
display ospf interface           # 查看 OSPF 接口
```

---

## 3. 思科实现（IOS-XE / IOS-XR / NX-OS）

### 3.1 基础配置

```bash
router ospf 1
 router-id 1.1.1.1
 network 10.1.1.0 0.0.0.255 area 0
 network 10.2.1.0 0.0.0.255 area 1
```

### 3.2 关键特性

- **区域 ID 只支持整数**：`area 0` 或 `area 1`，**不接受** `area 0.0.0.0`
- **接口开销**：`ip ospf cost <value>`
- **DR 优先级**：`ip ospf priority <0-255>`
- **认证**：`area 0 authentication message-digest` + `ip ospf message-digest-key 1 md5 <key>`

### 3.3 常用维护命令

```bash
show ip ospf neighbor            # 查看邻居
show ip ospf database            # 查看 LSDB
show ip ospf route               # 查看 OSPF 路由
show ip ospf interface brief     # 查看 OSPF 接口
```

---

## 4. 厂商差异对比

| 维度 | Huawei | Cisco |
|------|--------|-------|
| 区域 ID 格式 | 支持整数 / 点分十进制 | 仅支持整数 |
| Router ID 选举 | Loopback → 物理接口 IP 最大 | 同 |
| 网络类型关键字 | `broadcast` / `nbma` / `p2p` / `p2mp` | `broadcast` / `non-broadcast` / `point-to-point` / `point-to-multipoint` |
| Stub 区域 | `stub` / `nssa` | `area X stub` / `area X nssa` |
| 邻居震荡抑制 | `ospf peer hold-max-cost` | 无对应命令（通过 route dampening 替代） |
| 默认 Hello/Dead | P2P: 10/40, MA: 10/40, NBMA: 30/120 | 同 |
| 接口开销自动计算 | 同 Cisco | 同 Huawei |
| LSDB 过载保护 | `lsdb-overflow-limit` | `max-lsa <n>` |

---

## 5. 实战配置示例

### 场景

R1 - R2 - R3 串联，全部在 Area 0。

#### 5.1 华为配置

```bash
# R1
sysname R1
interface GigabitEthernet0/0/0
 ip address 10.1.12.1 255.255.255.252
interface LoopBack0
 ip address 1.1.1.1 255.255.255.255
ospf 1 router-id 1.1.1.1
 area 0.0.0.0
  network 10.1.12.0 0.0.0.3
  network 1.1.1.1 0.0.0.0
```

```bash
# R2
sysname R2
interface GigabitEthernet0/0/0
 ip address 10.1.12.2 255.255.255.252
interface GigabitEthernet0/0/1
 ip address 10.1.23.2 255.255.255.252
interface LoopBack0
 ip address 2.2.2.2 255.255.255.255
ospf 1 router-id 2.2.2.2
 area 0.0.0.0
  network 10.1.12.0 0.0.0.3
  network 10.1.23.0 0.0.0.3
  network 2.2.2.2 0.0.0.0
```

```bash
# R3 略，对称即可
```

#### 5.2 思科配置

```bash
# R1
hostname R1
interface GigabitEthernet0/0
 ip address 10.1.12.1 255.255.255.252
 no shutdown
interface Loopback0
 ip address 1.1.1.1 255.255.255.255
router ospf 1
 router-id 1.1.1.1
 network 10.1.12.0 0.0.0.3 area 0
 network 1.1.1.1 0.0.0.0 area 0
```

#### 5.3 验证

```bash
# 华为
display ospf peer brief
# 期望：看到 R2 / R3，State 为 Full

# 思科
show ip ospf neighbor
# 期望：看到 R2 / R3，State 为 FULL
```

---

## 6. 常见面试题

### Q1：邻居卡在 2-Way 不动了，可能是什么原因？

**A**：
1. MA 网络中，所有路由器优先级相同（默认 1），IP 大者成为 DR，**不会卡 2-Way**
2. 实际上"卡 2-Way"通常是因为 **BDR 选举已完成，DROther 之间维持在 2-Way**
3. 如果你期望 Full 但只有 2-Way，检查网络类型（NBMA 配错 neighbor 语句）

### Q2：LSA Type-3 由谁生成？范围是什么？

**A**：
- 由 **ABR** 生成
- 范围：泛洪到**除本区域外的所有区域**
- 内容：区域间路由（每个区域一个 Type-3 LSA）

### Q3：Stub 区域里不允许哪些 LSA？为什么？

**A**：
- 不允许 Type-5（AS External）和 Type-4（ASBR Summary）
- 因为 Stub 区域的目的是"减少路由表"，不学外部路由
- 通过 `default-route` 由 ABR 下发默认路由代替

### Q4：华为和思科 OSPF 最大的命令差异是什么？

**A**：
1. 区域 ID 格式（华为支持点分十进制）
2. 进入接口配置模式的方式（`interface GigabitEthernet` vs `interface GigabitEthernet0/0/0`）
3. DR 优先级命令前缀（`ospf dr-priority` vs `ip ospf priority`）

---

## 7. 参考资料

- [RFC 2328 - OSPF Version 2](https://www.rfc-editor.org/rfc/rfc2328)
- [RFC 5709 - OSPFv2 HMAC-SHA Cryptographic Authentication](https://www.rfc-editor.org/rfc/rfc5709)
- 华为 NE40E 产品文档 - OSPF 配置
- Cisco OSPF Configuration Guide
- 自己的实验笔记：[lab/compare/ospf-basic.md](../../lab/compare/ospf-basic.md)

## 8. 变更记录

| 日期 | 改动 | 作者 |
|------|------|------|
| 2024-07-20 | 初稿 | @awuawuheiyohei |

---

*这只是 OSPF 入门级，完整版要再覆盖：特殊区域（Stub / NSSA / Totally Stubby）、OSPFv3、认证机制、路由汇总、邻居认证、排障流程等。后续 PR 持续完善。*
