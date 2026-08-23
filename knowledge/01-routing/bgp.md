# BGP（Border Gateway Protocol）

> 路径矢量路由协议，互联网事实上的 EGP 标准。
> 唯一支持大规模多归属、策略路由的 IGP/EGP。

## 1. 原理

### 1.1 核心机制

- **AS（Autonomous System）**：16-bit ASN（1-65535），扩展后 32-bit
- **Path Vector**：路由携带 AS 路径信息（AS_PATH）
- **TCP 179**：BGP 运行在 TCP 之上，靠 TCP 提供可靠性
- **三种邻居关系**：
  - **EBGP**（External BGP）：不同 AS 之间，默认 TTL=1
  - **IBGP**（Internal BGP）：同一 AS 内部，默认 TTL=255，不传播
  - **RR（Route Reflector）**：打破 IBGP 全互联限制

### 1.2 报文类型

| 报文 | 作用 | 何时发 |
|------|------|--------|
| **Open** | 建立邻居，含 ASN、Router ID、Hold Time | TCP 连接后 |
| **Keepalive** | 维持邻居（默认 60s） | 周期性 |
| **Update** | 路由更新（含 NLRI + 路径属性） | 路由变化时 |
| **Notification** | 错误通知 + 关闭连接 | 出错时 |
| **Route-Refresh**（可选） | 触发路由重发 | 策略变化时 |

### 1.3 邻居建立状态机

```
Idle → Connect → Active → OpenSent → OpenConfirm → Established
```

| 状态 | 含义 |
|------|------|
| Idle | 初始状态，等待 Start 事件 |
| Connect | TCP 连接建立中 |
| Active | TCP 连接失败，重试 |
| OpenSent | TCP 已建立，发出 Open |
| OpenConfirm | 收到对端 Open |
| Established | 邻居建立完成，可交换 Update |

**关键事件**：
- 卡在 Active：通常对端没配 neighbor、或认证/ACL 问题
- Established 后 Hold Time 内没收到 Keepalive 也会断

### 1.4 路径属性

#### Well-known Mandatory（公认必遵）

| 属性 | 含义 | 用途 |
|------|------|------|
| **Origin** | 路由起源 | IGP > EGP > Incomplete（选路优先级） |
| **AS_PATH** | AS 路径列表 | 选路 + 环路检测 |
| **Next_Hop** | 下一跳 | 转发 |

#### Well-known Discretionary（公认任意）

| 属性 | 含义 |
|------|------|
| **Local_Pref** | 本地优先级，**只在 IBGP 内传递** |
| **Atomic_Aggregate** | 聚合标记 |

#### Optional Transitive（可选传递）

| 属性 | 含义 |
|------|------|
| **Community** | 团体属性，用于标记和策略 |
| **Aggregator** | 聚合者信息 |
| **Multi_Exit_Disc (MED)** | 多出口鉴别器 |

#### Optional Non-transitive（可选非传递）

| 属性 | 含义 |
|------|------|
| **Originator_ID** | RR 防环 |
| **Cluster_List** | RR 集群防环 |

### 1.5 Best Path 选择顺序

按 RFC 4271 + 各厂商扩展：

1. **Weight** 最大（Cisco 私有，**本地有效**）
2. **Local_Pref** 最大（IBGP 内传递）
3. **Locally originated**（本路由器自己产生的路由，weight 32768）
4. **AS_PATH** 最短
5. **Origin** 最小（IGP < EGP < Incomplete）
6. **MED** 最小（**只在同一邻居 AS 的多个路径间比较**）
7. **EBGP > IBGP**（eBGP 路径优先）
8. **IGP next-hop** 到下一跳最近的路径
9. **Oldest** EBGP path
10. **Router ID** 最小（来自邻居的）
11. **Cluster_List** 最短
12. **Neighbor IP** 最小

## 2. 华为实现

### 2.1 基础配置

```bash
# 配置 BGP
bgp 65010
 router-id 1.1.1.1
 peer 10.1.12.2 as-number 65020                # EBGP 邻居
 peer 2.2.2.2 as-number 65010                  # IBGP 邻居（用 Loopback）
 peer 2.2.2.2 connect-interface LoopBack0       # 指定源接口

 # 引入路由
 ipv4-family unicast
  network 10.1.0.0 255.255.0.0
  peer 10.1.12.2 enable
  peer 2.2.2.2 enable
  peer 2.2.2.2 next-hop-local                   # 向 IBGP 邻居改 next-hop 为自己
```

### 2.2 关键特性

- **ASN 格式**：支持 4-byte ASN（如 65010.100 或 plain 65010）
- **Route Reflector 角色**：
  ```bash
  bgp 65010
   ipv4-family unicast
    reflector cluster-id 1.1.1.1
    peer 2.2.2.2 reflect-client
  ```
- **Confederation**（联盟）：
  ```bash
  bgp 65010
   confederation id 100
   confederation peer-as 65020 65030
  ```
- **团体属性**：
  ```bash
  bgp 65010
   ipv4-family unicast
    peer 10.1.12.2 advertise-community
  ```

### 2.3 常用维护命令

```bash
display bgp peer                    # 邻居状态
display bgp routing-table           # BGP 路由表
display bgp routing-table peer 10.1.12.2 received-routes  # 从某邻居收到的路由
display bgp paths                  # 所有 AS_PATH
reset bgp all                       # 重置所有邻居（慎用）
```

## 3. 思科实现（IOS-XE / IOS-XR）

### 3.1 基础配置

```bash
router bgp 65010
 bgp router-id 1.1.1.1
 neighbor 10.1.12.2 remote-as 65020
 neighbor 2.2.2.2 remote-as 65010
 neighbor 2.2.2.2 update-source Loopback0

 address-family ipv4
  network 10.1.0.0 mask 255.255.0.0
  neighbor 10.1.12.2 activate
  neighbor 2.2.2.2 activate
  neighbor 2.2.2.2 next-hop-self
```

### 3.2 关键特性

- **Weight 属性**（Cisco 私有）：
  ```bash
  neighbor 10.1.12.2 weight 100
  # 或在 route-map 中 set weight
  ```
- **Local_Pref**：
  ```bash
  bgp default local-preference 200   # 全局默认值
  ```
- **MED**：
  ```bash
  route-map SET_MED permit 10
   set metric 50
  neighbor 10.1.12.2 route-map SET_MED out
  ```
- **Community**：
  ```bash
  neighbor 10.1.12.2 send-community both
  ```

### 3.3 常用维护命令

```bash
show ip bgp summary                 # 邻居摘要
show ip bgp                         # BGP 路由表
show ip bgp regexp ^65020_          # AS_PATH 正则过滤
show ip bgp neighbors 10.1.12.2 received-routes
clear ip bgp * soft                 # 软重置（不破坏 TCP）
```

## 4. 厂商差异对比

| 维度 | Huawei | Cisco |
|------|--------|-------|
| 进入 BGP 模式 | `bgp <asn>` | `router bgp <asn>` |
| 邻居配置 | `peer <ip> as-number <asn>` | `neighbor <ip> remote-as <asn>` |
| 指定源接口 | `peer <ip> connect-interface <intf>` | `neighbor <ip> update-source <intf>` |
| IBGP 改下一跳 | `peer <ip> next-hop-local` | `neighbor <ip> next-hop-self` |
| RR 客户端配置 | `peer <ip> reflect-client` | `neighbor <ip> route-reflector-client` |
| 联盟 ID | `confederation id <id>` | `bgp confederation identifier <id>` |
| 联盟 peer | `confederation peer-as <asn1> <asn2>` | `bgp confederation peers <asn1> <asn2>` |
| 引入路由 | `network <ip> <mask>` | `network <ip> mask <mask>` |
| 看邻居 | `display bgp peer` | `show ip bgp summary` |
| 看路由 | `display bgp routing-table` | `show ip bgp` |
| 软重置 | `refresh bgp` | `clear ip bgp <ip> soft` |
| **Weight** | 不支持 | 支持（默认 0，本地 32768） |
| **MED** | `route-policy` 设置 | `set metric` 或 `default-metric` |
| 软重置命令 | `refresh bgp <ip> <soft>` | `clear ip bgp <ip> soft` |
| 4-byte ASN | 支持（65010.100 格式） | 支持（asplain 格式） |
| eBGP 多跳 | `peer <ip> ebgp-max-hop <n>` | `neighbor <ip> ebgp-multihop <n>` |
| 路由聚合 | `aggregate <ip> <mask>` | `aggregate-address <ip> <mask>` |

## 5. 实战配置示例

### 场景

AS 65010 通过 EBGP 连接到 AS 65020。AS 65010 内部有 3 台路由器，做全互联 IBGP。

#### 拓扑

```
       AS 65020                    AS 65010
   [R5] --- EBGP --- [R1] --- IBGP --- [R2]
                        |
                       IBGP
                        |
                       [R3]
```

#### 5.1 华为配置

```bash
# R1 (ASBR)
sysname R1
interface GigabitEthernet0/0/0
 ip address 10.1.15.1 255.255.255.252
interface LoopBack0
 ip address 1.1.1.1 255.255.255.255

bgp 65010
 router-id 1.1.1.1
 peer 10.1.15.5 as-number 65020
 peer 2.2.2.2 as-number 65010
 peer 2.2.2.2 connect-interface LoopBack0
 peer 3.3.3.3 as-number 65010
 peer 3.3.3.3 connect-interface LoopBack0
 #
 ipv4-family unicast
  network 10.1.0.0 255.255.0.0
  peer 10.1.15.5 enable
  peer 2.2.2.2 enable
  peer 2.2.2.2 next-hop-local
  peer 3.3.3.3 enable
  peer 3.3.3.3 next-hop-local
```

```bash
# R2
sysname R2
interface LoopBack0
 ip address 2.2.2.2 255.255.255.255

bgp 65010
 router-id 2.2.2.2
 peer 1.1.1.1 as-number 65010
 peer 1.1.1.1 connect-interface LoopBack0
 peer 3.3.3.3 as-number 65010
 peer 3.3.3.3 connect-interface LoopBack0
 #
 ipv4-family unicast
  network 10.2.0.0 255.255.0.0
  peer 1.1.1.1 enable
  peer 1.1.1.1 next-hop-local
  peer 3.3.3.3 enable
  peer 3.3.3.3 next-hop-local
```

#### 5.2 思科配置

```bash
# R1
hostname R1
interface GigabitEthernet0/0
 ip address 10.1.15.1 255.255.255.252
 no shutdown
interface Loopback0
 ip address 1.1.1.1 255.255.255.255

router bgp 65010
 bgp router-id 1.1.1.1
 neighbor 10.1.15.5 remote-as 65020
 neighbor 2.2.2.2 remote-as 65010
 neighbor 2.2.2.2 update-source Loopback0
 neighbor 3.3.3.3 remote-as 65010
 neighbor 3.3.3.3 update-source Loopback0
 !
 address-family ipv4
  network 10.1.0.0 mask 255.255.0.0
  neighbor 10.1.15.5 activate
  neighbor 2.2.2.2 activate
  neighbor 2.2.2.2 next-hop-self
  neighbor 3.3.3.3 activate
  neighbor 3.3.3.3 next-hop-self
```

#### 5.3 验证

```bash
# 华为
display bgp peer
# 期望：所有邻居 State = Established，Established time > 0

display bgp routing-table
# 期望：看到从 10.1.15.5 收到的 AS 65020 路由

# 思科
show ip bgp summary
show ip bgp
```

## 6. 排障命令

### 6.1 邻居建立问题

```bash
# 华为
display bgp peer <ip> verbose    # 看详细协商过程
display tcp status               # TCP 连接状态
debugging bgp all                # 调试（生产慎用）

# 思科
show ip bgp neighbors <ip>
debug ip bgp <ip> events
```

### 6.2 路由不通问题

```bash
# 华为
display bgp routing-table <ip>
display bgp routing-table <ip> peer <ip> received-routes   # 收到的路由
display bgp routing-table <ip> peer <ip> advertised-routes # 通告的路由

# 思科
show ip bgp <ip>
show ip bgp neighbors <ip> received-routes
show ip bgp neighbors <ip> advertised-routes
```

## 7. 常见面试题

### Q1: IBGP 为什么要全互联？RR 怎么解决？

**A**：
- IBGP 路由器**不会把从 IBGP 邻居学到的路由再传给其他 IBGP 邻居**（防环）
- AS 内 n 台路由器需要 n(n-1)/2 个 IBGP 邻居，规模化问题
- **Route Reflector** 允许打破这个规则：RR 客户端从 RR 学到的路由可以再传给其他客户端
- 3 个角色：RR（路由反射器）/ Client（客户端）/ Non-Client（普通 IBGP）
- 规则：RR 从 Client 收到的路由 → 反射给所有 Client 和 Non-Client；RR 从 Non-Client 收到的路由 → 只反射给 Client

### Q2: AS_PATH 防环的原理？

**A**：
- 当 BGP 路由穿越 AS 时，**本地 ASN 会被 prepend 到 AS_PATH 最左边**
- 收到路由时如果发现 AS_PATH 里**已经包含自己的 ASN**，就丢弃该路由
- 这就是为什么 eBGP 不会形成环路

### Q3: Local_Pref 和 MED 的区别？

**A**：
- **Local_Pref**：
  - 作用范围：**AS 内部**（只通过 IBGP 传递，不传给 EBGP）
  - 用途：影响**出方向**流量（从本 AS 出去选哪条路）
  - 默认值：100
- **MED**：
  - 作用范围：**跨 AS 传递**（传给 EBGP 邻居，再传给邻居的 IBGP）
  - 用途：影响**入方向**流量（影响邻居的选路）
  - 默认值：0

### Q4: BGP 卡在 Active 状态怎么排查？

**A**：
1. **对端没配 neighbor**（最常见）：本端发了 TCP SYN，没人响应
2. **ACL 阻止了 TCP 179**：`display acl all` / `show access-lists`
3. **认证密码不一致**：`display current-configuration | include peer` 看 keychain
4. **源 IP 不对**：BGP 用出接口 IP 作源，要和对端的 neighbor IP 匹配
5. **路由不可达**：对端 IP 不可达，先 `ping` 验证

### Q5: Weight 和 Local_Pref 都是影响选路的，区别？

**A**：
- **Weight**（Cisco 私有）：
  - 只在**本路由器**有效，不传给任何邻居
  - 范围：0-65535，默认 0，本地起源 32768
- **Local_Pref**：
  - 在**整个 AS 内部**有效（IBGP 传递）
  - 范围：0-4294967295，默认 100

## 8. 参考资料

- [RFC 4271 - A Border Gateway Protocol 4 (BGP-4)](https://www.rfc-editor.org/rfc/rfc4271)
- [RFC 4456 - BGP Route Reflection](https://www.rfc-editor.org/rfc/rfc4456)
- [RFC 5065 - Autonomous System Confederations for BGP](https://www.rfc-editor.org/rfc/rfc5065)
- 华为 NE40E 产品文档 - BGP 配置
- Cisco BGP Configuration Guide
- [CCIE 笔试真题集 - 2017](https://www.cisco.com/)

## 9. 变更记录

| 日期 | 改动 | 作者 |
|------|------|------|
| 2026-08-23 | 初稿（含双厂商对照表、状态机、12 步选路、排障命令、5 道面试题） | @awuawuheiyohei |

---

*下一步：写 CCIE 笔试题考 BGP 路径属性选择，写 Huawei lab 考 OSPF 多区域汇总。*
