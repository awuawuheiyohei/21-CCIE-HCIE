---
id: HCIE-RS-I-2024-001
type: interview-q
vendor: Huawei
cert: HCIE-RS
stage: interview
date: 2024-08
source: 华为 HCIE 面试经验汇总（培训机构整理）+ RFC 2328 §10.1
source_url: https://www.rfc-editor.org/rfc/rfc2328#section-10.1
difficulty: 4/5
tags: [ospf, neighbor, state-machine, adjacency]
status: verified
verified_by: awuawuheiyohei
verified_date: 2026-08-23
created: 2026-08-23
updated: 2026-08-23
---

# OSPF 邻居建立过程的状态机是怎样的？每种状态的含义是什么？

## 题目

请描述 OSPF 邻居建立的全过程，包括涉及的报文类型、状态机转移、关键事件。
如果回答中涉及 MA（多路访问）网络，请特别说明 DR/BDR 的选举时机。

## 参考答案（要点）

### 1. 状态机转移

```
Down → Init → 2-Way → Exstart → Exchange → Loading → Full
```

### 2. 每个状态的含义

| 状态 | 含义 | 关键事件 |
|------|------|----------|
| **Down** | 初始状态，未收到对端任何 OSPF 报文 | 启动 OSPF 进程；或对端 Down |
| **Init** | 本端收到了对端的 Hello，但 Hello 中没看到自己的 Router ID | 收到对端 Hello |
| **2-Way** | 双向通信建立（Hello 中互相看到了对方） | MA 网络中**完成 DR/BDR 选举** |
| **Exstart** | 协商 Master / Slave，确定 DD 报文序列号起始值 | 双方互相发送空 DD |
| **Exchange** | 互相发送 DD 摘要，描述自己的 LSDB | DD 报文交换 |
| **Loading** | 互相发送 LSR / LSU / LSAck 详细同步 | LSR 链路状态请求 |
| **Full** | LSDB 完全同步，邻接关系建立 | 同步完成 |

### 3. 涉及报文

| 报文 | 作用 | 状态阶段 |
|------|------|----------|
| **Hello** | 发现 / 维持邻居、选举 DR/BDR | Init → 2-Way |
| **DD**（Database Description） | LSDB 摘要 | Exstart → Exchange |
| **LSR**（Link State Request） | 请求具体 LSA | Loading |
| **LSU**（Link State Update） | 发送 LSA 详情 | Loading |
| **LSAck**（Link State Acknowledgment） | 确认收到 LSU | Loading |

### 4. DR/BDR 选举

**时机**：发生在 2-Way 状态时（不是 Full）。

**规则**：
1. 优先级最大（默认 1，0 表示不参与）
2. Router ID 最大
3. 选举**非抢占**：一旦选举完成，即使新加入优先级更高的路由器也不会重新选举

**结果**：
- DROther 之间维持在 2-Way（不进入 Full）
- DR 与 DROther、BDR 与 DROther 之间形成 Full 邻接关系
- BDR 是 DR 的备份

### 5. 网络类型差异

| 网络类型 | 是否选举 DR/BDR | 邻居建立细节 |
|----------|-----------------|---------------|
| **Broadcast** | 是 | 自动发现邻居 |
| **P2P** | 否 | 直接进入 Exstart |
| **NBMA** | 是 | 需要手工指定 neighbor |
| **P2MP** | 否 | 类似 P2P |

## 追问点（面试官可能继续问）

### Q1: 邻居卡在 Init 状态可能是什么原因？

**A**：
- 邻居的 Hello 包**被 ACL 过滤**了（最常见）
- 邻居的 OSPF 区域不匹配
- 邻居的 Hello / Dead 间隔不一致
- 邻居的 Stub 区域标记不一致
- MA 网络中，本端接口在 MA 网络中，对方没把本端 Router ID 放进 Hello

### Q2: 卡在 2-Way 一定有问题吗？

**A**：**不一定**。MA 网络中，DROther 与 DROther 之间就是 2-Way 状态，这是正常的。
但如果**期望 Full 却卡在 2-Way**：
- 可能是 MA 网络没选举 DR（比如所有路由器优先级都是 0）
- 可能是 MTU 不一致（理论上 2-Way 后会卡在 Exstart）

### Q3: 卡在 Exstart 是什么原因？

**A**：
- **MTU 不一致**（最常见）：DD 报文超过接口 MTU，对方丢弃
- 区域 ID 不匹配
- 认证密码错误
- 某些厂商私有参数不一致（Huawei vs Cisco 互联时常见）

### Q4: 卡在 Exchange 是什么原因？

**A**：
- MTU 不一致（继续）
- 区域类型不匹配（如一端是 Stub，一端不是）
- 收到非法 LSA

### Q5: OSPF 和 BGP 邻居建立机制有什么本质区别？

**A**：
- **OSPF**：基于链路状态，自动发现邻居（除 NBMA），通过 Hello 维持
- **BGP**：基于 TCP（端口 179），需要**手工指定 neighbor**（除 IBGP 用 loopback 自发现）
- BGP 没有状态机概念，直接是 Idle → Connect → Active → OpenSent → OpenConfirm → Established

## 厂商差异

| 维度 | Huawei | Cisco |
|------|--------|-------|
| 显示邻居状态命令 | `display ospf peer brief` | `show ip ospf neighbor` |
| 卡 Init 排查命令 | `display ospf error` | `debug ip ospf hello` |
| 卡 Exstart 排查命令 | `display ospf peer` 看 MTU 字段 | `show ip ospf interface` 看 MTU |
| DR 优先级命令 | `ospf dr-priority <0-255>` | `ip ospf priority <0-255>` |
| 改接口 MTU | `mtu <value>` | `mtu <value>`（需要 reload） |

## 个人回答记录

> 2026-08-23 模拟面试（自练）

- **时长**：4 分钟
- **覆盖度**：完整覆盖 7 个状态 + 5 种报文 + DR 选举
- **漏点**：
  - 没主动提"网络类型对邻居建立的影响"
  - 卡 Exstart 原因答得不够细（漏了"MTU 协商机制"）
- **改进方向**：
  - 答案开头加一句"OSPF 邻居建立有 7 个状态 + 5 种报文"
  - 主动提一句"NBMA 网络需要手工配 neighbor"，引导追问
  - 练习把答案压到 3 分钟内，给追问留时间

## 关联知识点

- [knowledge/01-routing/ospf.md](../../../knowledge/01-routing/ospf.md)
- [RFC 2328 §10 - Neighbor and Adjacency formation](https://www.rfc-editor.org/rfc/rfc2328#section-10)

---

## 📚 参考资料

- [RFC 2328 - OSPF Version 2](https://www.rfc-editor.org/rfc/rfc2328)
- 华为 HCIE-RS 培训教材 - OSPF 章节
- 历年 HCIE 面试真题回忆（社区整理）

## 📝 变更记录

| 日期 | 改动 | 作者 |
|------|------|------|
| 2026-08-23 | 初稿（含个人模拟面试记录） | @awuawuheiyohei |
