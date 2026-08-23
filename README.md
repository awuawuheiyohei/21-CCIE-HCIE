# 🎯 CCIE × HCIE 备考知识库

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](./docs/CONTRIBUTING.md)
[![Lint Questions](https://github.com/awuawuheiyohei/CCIE-HCIE_Jarvis/actions/workflows/lint.yml/badge.svg)](./.github/workflows/lint.yml)
[![Maintained by awuawuheiyohei](https://img.shields.io/badge/maintained%20by-@awuawuheiyohei-blue.svg)](https://github.com/awuawuheiyohei)

> **双厂商对照** · **真题+模拟+知识点** · **完全开源**

一个为同时备考 **CCIE**（Cisco）和 **HCIE**（Huawei）两个网络工程师顶级认证而构建的
结构化、可追溯、可版本控制的备考资料库。

核心设计理念：**同一知识点，双厂商对照**——一次学习，复习两个厂商的实现差异，
最大化学习效率。

---

## 📑 目录导航

| 目录 | 说明 |
|------|------|
| [`docs/`](./docs) | 项目规范与学习路线 |
| [`knowledge/`](./knowledge) | 知识点体系（按主题分章，双厂商对照） |
| [`exams/`](./exams) | 真题 + 模拟题（按认证 / 阶段分类） |
| [`lab/`](./lab) | 实验配置笔记（huawei / cisco / compare） |
| [`resources/`](./resources) | 速查表、图解、参考资料 |
| [`scripts/`](./scripts) | 工具脚本（抽题、错题统计、进度追踪） |

---

## 🚀 快速开始

### 你是第一次来？

按这个顺序读：

1. **[学习路线](./docs/ROADMAP.md)** —— 搞清楚从 0 到拿证要打哪些仗
2. **[标签体系](./docs/TAG-SYSTEM.md)** —— 学会看每个文件顶部的"元数据"
3. **[题目格式规范](./docs/QUESTION-FORMAT.md)** —— 了解题库怎么组织
4. **[贡献指南](./docs/CONTRIBUTING.md)** —— 想补充内容？照这个来

### 找题做？

```
exams/
├── HCIE-RS/        # HCIE 路由交换
│   ├── written/    # 笔试
│   ├── lab/        # 实验
│   └── interview/  # 面试
├── CCIE-RS/        # CCIE 路由交换
│   └── ...
└── mocks/          # 自编模拟卷
```

### 查知识点？

```
knowledge/
├── 01-routing/         # 路由（OSPF / IS-IS / BGP ...）
├── 02-switching/       # 交换（VLAN / STP / VXLAN ...）
├── 03-mpls/            # MPLS / MPLS TE
├── 04-vpn/             # L3VPN / L2VPN / EVPN
├── 05-security/        # 安全（ACL / IPsec / MACsec ...）
├── 06-ipv6/            # IPv6
├── 07-qos/             # QoS
├── 08-automation/      # 自动化（NETCONF / YANG / Ansible）
└── 09-high-availability/  # 高可用（VRRP / M-LAG / Stack）
```

---

## ✨ 为什么做这个项目？

市面上的备考资料有几个痛点：

- **碎片化** —— 论坛、PDF、笔记散落各处，没法系统复习
- **单厂商视角** —— CCIE 资料讲 Cisco、HCIE 资料讲 Huawei，知识点重合部分完全没对照
- **不可追溯** —— 真题满天飞，但没人标"哪年、哪个版本、官方还是民间回忆"
- **不能协作** —— 一个人的笔记没法滚动迭代

这个项目尝试解决：

| 痛点 | 解法 |
|------|------|
| 碎片化 | 统一目录 + 统一文件格式（见 `docs/QUESTION-FORMAT.md`） |
| 单厂商视角 | 知识点文档强制要求 **Huawei × Cisco** 双实现对照 |
| 不可追溯 | 题目顶部强制元数据：`source` / `date` / `vendor` / `version` |
| 不能协作 | Git + GitHub Issue / PR，PR 模板里强制"改了什么、加了什么 source" |

---

## 🏗️ 题目与知识点规范

所有题目必须遵循 **[题目格式规范](./docs/QUESTION-FORMAT.md)**。

最小题目示例（选择题）：

```markdown
---
id: HCIE-RS-W-2024-001
type: single-choice
vendor: Huawei
stage: written
date: 2024-06
source: 华为官方模拟题库（HCIE-RS V3.0）
difficulty: 3/5
tags: [ospf, lsa, area]
---

# 关于 OSPF Type-4 LSA，下列说法正确的是？

A. 由 ABR 生成，描述到 ASBR 的路由
B. 由 ASBR 生成，描述外部路由
C. 泛洪到所有区域
D. 只在 Stub 区域泛洪

## 答案

**A**

## 解析

Type-4 LSA（ASBR Summary LSA）由 **ABR** 生成，用于通告 ASBR 的位置，
帮助其他区域的路由器找到 ASBR 所在位置。详见 [knowledge/01-routing/ospf.md](../knowledge/01-routing/ospf.md)。
```

完整规范见 `docs/QUESTION-FORMAT.md`。

---

## 🛠️ 工具脚本

```bash
# 抽取错题本（按 tag 筛选）
./scripts/quiz.sh --tag ospf --wrong-only

# 统计进度（每个分类下已做 / 正确率）
./scripts/stats.sh

# 生成模拟卷
./scripts/mock.sh --vendor Huawei --count 60
```

> 脚本功能持续完善中，欢迎贡献。

---

## 📊 进度看板

> 实时更新，PR 修改后自动刷新（计划中）

| 模块 | HCIE 完成度 | CCIE 完成度 |
|------|-------------|-------------|
| Routing | 🟨🟨🟨⬜⬜ 60% | 🟨🟨⬜⬜⬜ 40% |
| Switching | 🟨🟨⬜⬜⬜ 40% | 🟨🟨🟨⬜⬜ 60% |
| MPLS | 🟨⬜⬜⬜⬜ 20% | 🟨🟨⬜⬜⬜ 40% |
| ... | ... | ... |

---

## 🤝 贡献

欢迎 PR！请先读 [CONTRIBUTING.md](./docs/CONTRIBUTING.md)。

特别欢迎：
- 📝 补充真题回忆（标好 source / date）
- 🔧 修正现有解析
- 🆕 添加新知识点（双厂商对照）
- 🐛 报告错题 / 错别字

---

## 📜 许可

本项目采用 **MIT 许可证** —— 详见 [LICENSE](./LICENSE)。

> ⚠️ **注意**：项目内的真题回忆仅供学习参考，**不保证与实际考试完全一致**。
> 实际备考请以官方文档为准。

---

## 🙋 作者

[@awuawuheiyohei](https://github.com/awuawuheiyohei) —— 正在备考 CCIE / HCIE 的网络工程师。

目标是做一个"自己复习时愿意看、别人也能复用"的知识库。如果觉得有用，欢迎 ⭐ Star 支持一下。

---

*最后更新：见 [commit history](../../commits)*
