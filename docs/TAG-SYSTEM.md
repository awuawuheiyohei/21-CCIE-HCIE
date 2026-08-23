# 🏷️ 标签体系（Tag System）

> **目的**：让题目和知识点可以被多维度筛选、聚合、统计。

---

## 1. 标签分类

标签分**四层**：

| 层级 | 前缀 | 示例 | 说明 |
|------|------|------|------|
| 主题 | `topic:` | `topic:routing` | 大主题分类 |
| 技术 | `tech:` | `tech:ospf` | 具体技术 / 协议 |
| 子主题 | `sub:` | `sub:lsa` | 技术内的子概念 |
| 厂商 | `vendor:` | `vendor:huawei` | 厂商特定（一般自动从 front matter 取） |

> 实际上**大多数标签不需要前缀**——`ospf` 比 `topic:routing/tech:ospf` 更易读。
> 前缀用于**分类冲突时消歧**（如 `bgp` 既是路由协议也是安全概念）。

---

## 2. 主题标签（一级）

与 `knowledge/` 目录一一对应：

| Tag | 目录 | 说明 |
|-----|------|------|
| `routing` | `knowledge/01-routing/` | 路由协议（OSPF / IS-IS / BGP / RIP / EIGRP） |
| `switching` | `knowledge/02-switching/` | 二层交换（VLAN / STP / VXLAN / EVPN） |
| `mpls` | `knowledge/03-mpls/` | MPLS / MPLS TE / Segment Routing |
| `vpn` | `knowledge/04-vpn/` | L3VPN / L2VPN / IPsec / DMVPN |
| `security` | `knowledge/05-security/` | ACL / AAA / 防火墙 / MACsec |
| `ipv6` | `knowledge/06-ipv6/` | IPv6 协议 / 过渡技术 |
| `qos` | `knowledge/07-qos/` | QoS / 流量整形 / 拥塞管理 |
| `automation` | `knowledge/08-automation/` | NETCONF / YANG / Ansible / Telemetry |
| `high-availability` | `knowledge/09-high-availability/` | VRRP / BFD / M-LAG / Stack |

---

## 3. 技术标签（二级，常用）

### 路由
- `ospf` / `ospfv2` / `ospfv3` / `isis` / `bgp` / `rip` / `eigrp` / `static`

### 交换
- `vlan` / `stp` / `rstp` / `mstp` / `vxlan` / `evpn` / `lacp` / `stacking`

### MPLS
- `ldp` / `rsvp` / `mpls-te` / `sr` / `sr-mpls` / `srv6`

### VPN
- `l3vpn` / `l2vpn` / `vpws` / `vpls` / `ipsec` / `gre` / `dmvpn` / `l2tp`

### 安全
- `acl` / `aaa` / `radius` / `tacacs` / `dot1x` / `macsec` / `ipsec` / `nat`

### 高可用
- `vrrp` / `bfd` / `mlag` / `stack` / `issu` / `nsr` / `nsf`

### 自动化
- `netconf` / `yang` / `restconf` / `gNMI` / `ansible` / `telemetry` / `zabbix` / `snmp`

### 协议特性
- `lsa` / `area` / `neighbor` / `dr-bdr` / `summary` / `redistribution` / `route-filter` / `route-reflector` / `confederation`

---

## 4. 难度标签

题目的 `difficulty` 字段（**不要**作为 tag，用 front matter）：

| 值 | 含义 |
|----|------|
| `1/5` | 入门（识记） |
| `2/5` | 基础（理解） |
| `3/5` | 中等（应用） |
| `4/5` | 进阶（分析） |
| `5/5` | 高级（综合 / 排障） |

---

## 5. 阶段标签

题目 front matter `stage` 字段：

| 值 | 含义 |
|----|------|
| `written` | 笔试 |
| `lab` | 实验 |
| `interview` | 面试 |
| `mock` | 模拟卷（不出现在 front matter，放文件名/路径） |

---

## 6. 状态标签

题目 front matter `status` 字段：

| 值 | 含义 |
|----|------|
| `draft` | 草稿（解析不完整或来源不清） |
| `verified` | 已验证（至少一次独立核对正确） |
| `disputed` | 有争议（开 Issue 讨论） |
| `deprecated` | 已废弃（考纲变更后不再考） |

---

## 7. 使用建议

### 筛选

```bash
# 找所有 OSPF 实验题
grep -l "tags:.*ospf" exams/**/lab/*.md

# 找所有 v1.0 之前的 HCIE 真题
grep -l "version:.*V1.0\|version:.*1.0" exams/HCIE-RS/written/*.md
```

> 这些 grep 后续会封装成 `scripts/quiz.sh`。

### 标签组合

```markdown
tags: [ospf, lsa, type-4, asbr]
```

建议**每题 3-6 个 tag**，太少不精准，太多难维护。

### 标签更新

- 新增 tag：在本文档"二级"分类下追加，开 PR
- 合并 / 改名 tag：开 Issue 讨论 → 用 `scripts/retag.sh` 批量改

---

## 8. 反模式

❌ **错误用法**：

- 一题 20 个 tag —— 没意义
- 标签大小写不统一（`OSPF` vs `ospf`）—— 全用小写
- 中文 tag（`路由协议`）—— 全用英文，方便 grep / 脚本处理
- 厂商相关用 tag（`huawei`、`cisco`）—— 用 front matter 的 `vendor` 字段

✅ **正确**：

```yaml
tags: [ospf, lsa, type-4, asbr]
```

短、准、小写、英文。

---

*最后更新：见 git log*
