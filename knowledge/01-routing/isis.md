# IS-IS（Intermediate System to Intermediate System）

> ISO 10589 定义的链路状态协议，最初给 OSI 设计的，被 ISP 大量用于骨干网。
> 与 OSPF 同为 IGP 标杆，但市场份额更小、更"硬核"。

## 1. 原理

### 1.1 核心机制

- **CLNP（Connectionless Network Protocol）**：OSI 协议栈的网络层协议
- **NET（Network Entity Title）**：IS-IS 的"IP 地址"（其实是 NSAP）
- **两级层次**（与 OSPF 不同）：
  - **Level-1**：本区域内部，类似 OSPF 完全末梢
  - **Level-2**：区域间，类似 OSPF 骨干
  - **Level-1-2**：同时参与 L1 和 L2，类似 OSPF ABR
- **PDU（Protocol Data Unit）**：IS-IS 的"报文"，11 种类型

### 1.2 NET 地址格式

```
[Area ID].[System ID].00
```

| 字段 | 长度 | 用途 |
|------|------|------|
| **Area ID** | 1-13 字节 | 区域标识 |
| **System ID** | 6 字节（通常） | 路由器标识（常取 Loopback IP 拆分） |
| **NSEL**（N-selector） | 1 字节 | 服务标识，**ES 和 IS 都为 00** |

**示例**：
- `49.0001.1921.6800.0001.00`（49 = 私有 area ID，0001 = area 1，1921.6800.0001 = system ID 取自 192.168.0.1，00 = NSEL）
- 通常 System ID 取 Loopback 地址：192.168.0.1 → 1921.6800.0001

### 1.3 邻居建立（Hello 报文）

IS-IS 用 **3 次握手**建邻居（OSPF 是 2 次）：
1. Router A 发 P2P Hello（包含自己 System ID）
2. Router B 收到后**单播**回应 Hello（包含对端 System ID）
3. A 收到 B 的回应 → Up 状态

**状态机**：
```
Down → Initializing → Up
```

比 OSPF 简单（OSPF 7 个状态，IS-IS 只有 3 个）。

### 1.4 LSP（Link State PDU）

- 类似 OSPF 的 LSA
- 描述路由器的链路状态
- 由 Level-1-2 路由器在自己所属的 L1 区域里泛洪 L1 LSP，在 L2 骨干泛洪 L2 LSP
- **LSP ID** 格式：`<System ID>.<Pseudo-Node ID>.<LSP Number>`
  - 例：`1921.6800.0001.00-00`、`1921.6800.0001.00-01`（伪节点）

### 1.5 DIS（Designated Intermediate System）

类似 OSPF 的 DR，但**有选举**（非抢占）：

| 维度 | IS-IS DIS | OSPF DR |
|------|-----------|---------|
| 选举时机 | MA 网络启动时 | MA 网络中 |
| 抢占 | ✅ 是（IS-IS DIS 可被抢） | ❌ 否（OSPF DR 不可被抢） |
| 备份 | ❌ 无 BDR | ✅ 有 BDR |
| 优先级 | 0-127（默认 64） | 0-255（默认 1） |

### 1.6 网络类型

| 类型 | 选举 DIS | 邻居发现 |
|------|----------|----------|
| **Broadcast**（以太网） | ✅ 是 | 自动 |
| **P2P**（PPP / HDLC） | ❌ 否 | 自动 |

## 2. 华为实现

### 2.1 基础配置

```bash
# 全局启用 IS-IS
isis 1
 is-level level-1                        # level-1 / level-2 / level-1-2
 network-entity 49.0001.1921.6800.0001.00

# 接口启用 IS-IS
interface GigabitEthernet0/0/0
 isis enable 1
interface LoopBack0
 isis enable 1
```

### 2.2 关键特性

- **Wide Metric**：默认开启，支持大度量（24-bit 旧 / 32-bit 新）
- **路由渗透（Route Leaking）**：
  ```bash
  isis 1
   import-route isis level-2 into level-1    # L2 路由注入 L1
  ```
- **路由汇总**：
  ```bash
  isis 1
   summary 10.1.0.0 255.255.0.0 level-1-2
  ```
- **认证**：
  ```bash
  isis 1
   area-authentication-mode md5 1 cipher <key>    # 区域认证
   domain-authentication-mode md5 1 cipher <key>  # 域认证
  ```

### 2.3 常用维护命令

```bash
display isis peer                       # 邻居
display isis lsdb                      # LSDB
display isis routing-table             # IS-IS 路由
display isis interface                 # 接口 IS-IS 状态
display isis error                     # 错误统计
```

## 3. 思科实现（IOS-XE / IOS-XR）

### 3.1 基础配置

```bash
router isis 1
 net 49.0001.1921.6800.0001.00
 is-type level-1                        # level-1 / level-2 / level-1-2
 metric-style wide                      # 启用 wide metric

interface GigabitEthernet0/0
 ip router isis 1
interface Loopback0
 ip router isis 1
```

### 3.2 关键特性

- **Wide Metric**：`metric-style wide`
- **路由渗透**：
  ```bash
  router isis 1
   redistribute isis ip level-2 into level-1
  ```
- **路由汇总**：
  ```bash
  router isis 1
   summary-address 10.1.0.0 255.255.0.0
  ```
- **认证**：
  ```bash
  interface GigabitEthernet0/0
   isis authentication mode md5
   isis authentication key-chain <keychain-name>
  ```

### 3.3 常用维护命令

```bash
show isis neighbors
show isis database
show isis topology
show clns neighbors                     # ISO 邻居
show isis interface
```

## 4. 厂商差异对比

| 维度 | Huawei | Cisco |
|------|--------|-------|
| 进入 IS-IS 模式 | `isis <process-id>` | `router isis <process-id>` |
| NET 配置 | `network-entity <net>` | `net <net>` |
| 接口启用 | `isis enable <id>` | `ip router isis <tag>` |
| 路由器级别 | `is-level level-1` | `is-type level-1` |
| 路由渗透 | `import-route isis level-2 into level-1` | `redistribute isis ip level-2 into level-1` |
| 路由汇总 | `summary <ip> <mask> level-1-2` | `summary-address <ip> <mask>` |
| 区域认证 | `area-authentication-mode` | `authentication mode` (interface) |
| 邻居命令 | `display isis peer` | `show isis neighbors` |
| LSDB 命令 | `display isis lsdb` | `show isis database` |
| DIS 优先级 | `isis dis-priority <0-127>` | `isis priority <0-127>` |
| Wide metric | 默认开启 | `metric-style wide` 需手动 |
| 邻居建立 | P2P 3 次握手 | P2P 3 次握手 |
| 伪节点 LSP | 00-01 | 00-01 |

## 5. 实战配置示例

### 场景

3 台路由器：R1（Level-1）、R2（Level-1-2）、R3（Level-2）。R1-R2-R3 串联。

#### 5.1 华为配置

```bash
# R1 (L1)
sysname R1
isis 1
 is-level level-1
 network-entity 49.0001.1921.6800.0001.00
#
interface GigabitEthernet0/0/0
 ip address 10.0.12.1 255.255.255.252
 isis enable 1
interface LoopBack0
 ip address 1.1.1.1 255.255.255.255
 isis enable 1
```

```bash
# R2 (L1-2)
sysname R2
isis 1
 is-level level-1-2
 network-entity 49.0001.1921.6800.0002.00
#
interface GigabitEthernet0/0/0
 ip address 10.0.12.2 255.255.255.252
 isis enable 1
interface GigabitEthernet0/0/1
 ip address 10.0.23.2 255.255.255.252
 isis enable 1
interface LoopBack0
 ip address 2.2.2.2 255.255.255.255
 isis enable 1
```

```bash
# R3 (L2)
sysname R3
isis 1
 is-level level-2
 network-entity 49.0002.1921.6800.0003.00
#
interface GigabitEthernet0/0/0
 ip address 10.0.23.3 255.255.255.252
 isis enable 1
interface LoopBack0
 ip address 3.3.3.3 255.255.255.255
 isis enable 1
```

#### 5.2 思科配置

```bash
# R1
router isis 1
 net 49.0001.1921.6800.0001.00
 is-type level-1
 metric-style wide
!
interface GigabitEthernet0/0
 ip address 10.0.12.1 255.255.255.252
 ip router isis 1
!
interface Loopback0
 ip address 1.1.1.1 255.255.255.255
 ip router isis 1
```

#### 5.3 验证

```bash
# 华为
display isis peer
# 期望：R1-R2 (L1) Established，R2-R3 (L2) Established

display isis routing-table
# 期望：
#   R1 看到：自己区域路由 + R3 路由（如果 L2 渗透到 L1）
#   R2 看到：所有路由
#   R3 看到：L2 路由

# 思科
show isis neighbors
show isis topology
```

## 6. IS-IS vs OSPF 对比

| 维度 | IS-IS | OSPF |
|------|-------|------|
| 标准化组织 | ISO（10589） | IETF（RFC 2328） |
| 协议栈 | OSI（原生） | IP（原生） |
| 网络层 | CLNP | IP |
| 区域设计 | Level-1 / Level-2 | Area 0 / 非骨干 |
| 扩展性 | 更好（骨干 vs 区域分离） | 一般（所有区域连 Area 0） |
| 部署占比 | 运营商骨干多 | 企业网多 |
| 厂商支持 | 主流 | 主流 |
| 学习曲线 | 较陡（NSAP / NET） | 较平 |
| 报文 | 9 种 PDU（IIH, LSP, SNP...） | 5 种（Hello, DD, LSR, LSU, LSAck） |
| DIS/DR | 可抢占，无 BDR | 不可抢占，有 BDR |
| 默认认证 | 无 | 无 |
| 路由渗透 | 显式命令 | 自动（区域间 LSA Type-3） |

## 7. 常见面试题

### Q1: IS-IS 和 OSPF 最大的区别是什么？

**A**：
- **OSPF 强耦合 Area 0**：所有非骨干区域必须直连 Area 0，新增区域要改骨干
- **IS-IS 弱耦合 L2 骨干**：L2 路由器形成"骨干云"，L1 区域只要"接入"这个云就行，更灵活
- 实际上 OSPF 设计上 Area 0 是"链形"的（必须连成一片），IS-IS 的 L2 骨干是"网状"的（任意 L2 路由器互联即可）

### Q2: NET 地址怎么取 System ID？

**A**：
- 常用 Loopback IP 拆分（每 4 位一组用 3 段）：
  - 192.168.0.1 → 1921.6800.0001
  - 10.0.0.1 → 0100.0000.0001
- 必须是 6 字节（其他长度也合法但麻烦）
- 一个进程只能有一个 NET

### Q3: IS-IS DIS 和 OSPF DR 有什么不同？

**A**：
- **DIS 可抢占**：新加入路由器优先级更高会立刻抢占
- **OSPF DR 不可抢占**：选举完成后锁死，即使新设备优先级更高也不重选
- **IS-IS 无 BDR**：只有一个 DIS；OSPF 有 BDR 作为备份

### Q4: 路由渗透（Route Leaking）是干嘛的？

**A**：
- L1 路由器**默认只看到本区域路由 + 1 个默认路由指向 L1-2 ABR**
- 路由渗透让 L1 路由器**学到具体的 L2 区域路由**（不只是默认）
- 场景：L1 区域内有多个出口，不想走次优的默认路由
- 配置：
  - Huawei: `import-route isis level-2 into level-1`
  - Cisco: `redistribute isis ip level-2 into level-1`

### Q5: 邻居起不来怎么排查？

**A**：
- **NET 不在同一区域**：L1 和 L2 不能建邻居
- **Level 不匹配**：L1 只能和 L1 或 L1-2 建邻居
- **接口 MTU 不一致**（P2P 网络）
- **Hello 间隔不匹配**：`isis timer hello <sec>` 配置

## 8. 参考资料

- [RFC 1195 - Use of OSI IS-IS for Routing in TCP/IP and Dual Environments](https://www.rfc-editor.org/rfc/rfc1195)
- [ISO 10589 - IS-IS Intra-Domain Routing Protocol](https://www.iso.org/standard/30936.html)
- 华为 NE40E 产品文档 - IS-IS 配置
- Cisco IS-IS Configuration Guide

## 9. 变更记录

| 日期 | 改动 | 作者 |
|------|------|------|
| 2026-08-23 | 初稿（原理 + 厂商配置 + 6 个对比表 + 5 道面试题） | @awuawuheiyohei |

---

*下一步：跟用户确认"模拟器方向"——是 ContainerLab + FRR，还是 eNSP 拓扑，还是别的。*
