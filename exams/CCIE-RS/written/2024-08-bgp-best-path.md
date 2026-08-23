---
id: CCIE-RS-W-2024-001
type: single-choice
vendor: Cisco
cert: CCIE-RS
stage: written
date: 2024-06
source: Cisco 官方 350-401 / 400-101 模拟题库 + RFC 4271 §9.1
source_url: https://www.rfc-editor.org/rfc/rfc4271#section-9.1
difficulty: 4/5
tags: [bgp, best-path, path-attribute, route-selection]
status: verified
verified_by: awuawuheiyohei
verified_date: 2026-08-23
created: 2026-08-23
updated: 2026-08-23
---

# 思科路由器从 3 个 EBGP 邻居收到同一个前缀 192.168.1.0/24 的路由：

- 邻居 A：Weight=0，Local_Pref=100，AS_PATH=「65020 65030」，MED=50，EBGP
- 邻居 B：Weight=100，Local_Pref=100，AS_PATH=「65020 65040」，MED=50，EBGP
- 邻居 C：Weight=0，Local_Pref=150，AS_PATH=「65050」，MED=50，EBGP

# 路由器最终会选择哪条路由？

A. 邻居 A
B. 邻居 B
C. 邻居 C
D. 形成等价路由，3 条都用

## 答案

**B. 邻居 B**

## 解析

按 Cisco BGP best path 12 步选择（顺序敏感），逐步比较：

| 步骤 | 比较项 | 邻居 A | 邻居 B | 邻居 C | 胜者 |
|------|--------|--------|--------|--------|------|
| 1 | **Weight** 最大 | 0 | **100** | 0 | **B** ✅ |
| 2 | Local_Pref 最大 | 100 | 100 | 150 | C |
| ... | ... | ... | ... | ... | ... |

**第 1 步就决出胜负了**——邻居 B 的 Weight=100 最大，直接胜出，不再比较后续步骤。

### 完整 12 步选择顺序（背下来）

1. **Weight 最大**（Ciso 私有，0-65535，默认 0，本地起源 32768）
2. **Local_Pref 最大**（IBGP 传递，0-4294967295，默认 100）
3. **本路由器起源**（`network` / `aggregate` /  redistributed）
4. **AS_PATH 最短**
5. **Origin 最小**（IGP < EGP < Incomplete）
6. **MED 最小**（仅同 AS 多路径比较）
7. **eBGP > iBGP > Confederation**
8. **到 next-hop 的 IGP metric 最小**
9. **最老的 eBGP 路径**（如果是 eBGP）
10. **Router ID 最小**
11. **Cluster_List 最短**
12. **Neighbor IP 最小**

### 为什么不是 A、C、D？

- **不是 A**：A 的 Weight=0，比 B 的 100 小，第 1 步就被淘汰
- **不是 C**：C 的 Local_Pref=150 虽大，但 Weight=0，第 1 步就被淘汰（永远轮不到比较 Local_Pref）
- **不是 D**：B 在第 1 步就明确胜出，不构成等价路由（除非 Weight 也相同）

### 易错点

- ⚠️ **Weight 只在本路由器有效**，不传给任何邻居。每个路由器可以独立设置 Weight
- ⚠️ **Local_Pref 跨 AS 不传**（不传给 EBGP 邻居），只通过 IBGP 在本 AS 内传递
- ⚠️ **MED 只有"同 AS 多路径"之间才比较**——上题 3 个邻居分别来自 AS 65020、65050（不是同 AS），MED 不参与比较
- ⚠️ **"max" 和 "min" 的方向容易记错**——Weight/Local_Pref/AS_PATH/Origin/MED/.../Router ID 哪个用 max、哪个用 min，要单独记

## 厂商差异

| 维度 | Cisco | Huawei |
|------|-------|--------|
| Weight 属性 | ✅ 支持 | ❌ 不支持（用 routing-policy 模拟） |
| Local_Pref 范围 | 0-4294967295 | 0-4294967295 |
| Local_Pref 命令 | `bgp default local-preference 200` | `default local-preference 200` |
| MED 命令 | `default-metric 50` | `default med 50` |
| 选路优先级 | 见上面 12 步 | 8 步（无 Weight，第 1 步是 Preferred Value） |
| Preferred Value | 不存在 | **Huawei 私有**（0-65535，本地有效，类似 Cisco Weight） |

### Huawei 选路 8 步

1. **Preferred Value** 最大（Huawei 私有）
2. Local_Pref 最大
3. 本地起源
4. AS_PATH 最短
5. Origin 最小
6. MED 最小
7. EBGP > IBGP > Confederation
8. IGP next-hop metric 最小

> 也就是说：**Huawei 1 步 ≈ Cisco 1+2 步**。Huawei 1 个属性干了 Cisco 2 个属性的事。

## 关联知识点

- [knowledge/01-routing/bgp.md](../../../knowledge/01-routing/bgp.md)
- [RFC 4271 §9.1 - Decision Process](https://www.rfc-editor.org/rfc/rfc4271#section-9.1)

---

## 📚 参考资料

- [RFC 4271 - A Border Gateway Protocol 4 (BGP-4)](https://www.rfc-editor.org/rfc/rfc4271)
- Cisco CCIE Routing and Switching v5.1 Official Cert Guide
- [Cisco BGP Best Path Selection Algorithm](https://www.cisco.com/c/en/us/support/docs/ip/border-gateway-protocol-bgp/13753-25.html)

## 📝 变更记录

| 日期 | 改动 | 作者 |
|------|------|------|
| 2026-08-23 | 初稿 | @awuawuheiyohei |
