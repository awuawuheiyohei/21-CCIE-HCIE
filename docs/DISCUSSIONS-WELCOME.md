# 📌 仓库使用说明 + 贡献者欢迎帖

> 复制下方正文，粘到 GitHub Discussions 的 📣 Announcements 分类里发布。

---

## 正文（从这里开始复制）

## 👋 欢迎来到 CCIE × HCIE 备考知识库

这个仓库是我（[@awuawuheiyohei](https://github.com/awuawuheiyohei)）备考 **CCIE**（Cisco）和 **HCIE**（Huawei）过程中整理的结构化资料库。

> **核心设计理念**：同一知识点，双厂商对照。一次学习，复盘两个厂商的实现差异。

---

## 🗺️ 从哪里开始？

### 第一次来

按这个顺序读：

1. **[README](https://github.com/awuawuheiyohei/CCIE-HCIE_Jarvis/blob/main/README.md)** —— 5 分钟了解项目全貌
2. **[学习路线 ROADMAP](https://github.com/awuawuheiyohei/CCIE-HCIE_Jarvis/blob/main/docs/ROADMAP.md)** —— 12-18 月拿证规划
3. **[题目格式规范](https://github.com/awuawuheiyohei/CCIE-HCIE_Jarvis/blob/main/docs/QUESTION-FORMAT.md)** —— 理解每个文件怎么组织的
4. **[标签体系](https://github.com/awuawuheiyohei/CCIE-HCIE_Jarvis/blob/main/docs/TAG-SYSTEM.md)** —— 学会用 tag 过滤题目

### 找题做

```
exams/
├── HCIE-RS/         # 华为路由交换
│   ├── written/     # 笔试
│   ├── lab/         # 实验
│   └── interview/   # 面试
├── CCIE-RS/         # 思科路由交换
│   └── ... (同上)
└── mocks/           # 自编模拟卷
```

### 查知识点

```
knowledge/
├── 01-routing/          # 路由（OSPF / IS-IS / BGP / ...）
├── 02-switching/        # 交换（VLAN / STP / VXLAN / ...）
├── 03-mpls/             # MPLS / TE / SR
├── 04-vpn/              # L3VPN / L2VPN / EVPN / IPsec
├── 05-security/         # ACL / AAA / MACsec / ...
├── 06-ipv6/
├── 07-qos/
├── 08-automation/       # NETCONF / YANG / Ansible
└── 09-high-availability/  # VRRP / BFD / M-LAG
```

每个协议 / 技术点都有 **Huawei × Cisco** 双厂商对照表。

---

## 🤝 我能贡献什么？

| 类型 | 难度 | 影响 |
|------|------|------|
| 补充真题回忆（标好 source / date） | ⭐⭐ | 大 |
| 修正错别字 / 错误解析 | ⭐ | 中 |
| 补全双厂商对照表 | ⭐⭐⭐ | 大 |
| 新增 `knowledge/` 知识点 | ⭐⭐⭐ | 大 |
| 完善工具脚本 | ⭐⭐⭐ | 中 |
| 报告 Bug / 提建议 | ⭐ | 中 |

**第一次贡献？** 建议从"修正错别字"或"补充 1-2 道真题回忆"开始，PR 流程走一遍就熟了。

详细流程见 [CONTRIBUTING.md](https://github.com/awuawuheiyohei/CCIE-HCIE_Jarvis/blob/main/docs/CONTRIBUTING.md)。

---

## 📊 当前进度

> 实时更新，PR 修改后自动刷新

| 模块 | HCIE | CCIE |
|------|------|------|
| Routing | 🟨🟨🟨⬜⬜ 60% | 🟨🟨⬜⬜⬜ 40% |
| Switching | 🟨🟨⬜⬜⬜ 40% | 🟨🟨🟨⬜⬜ 60% |
| MPLS | 🟨⬜⬜⬜⬜ 20% | 🟨🟨⬜⬜⬜ 40% |
| 安全 / VPN / IPv6 / QoS / 自动化 / 高可用 | ⬜⬜⬜⬜⬜ | ⬜⬜⬜⬜⬜ |

> 目前处于 **Stage 1: 基础打底** 阶段，OSPF 知识点已上线（双厂商对照示例）。

---

## 💬 怎么交流？

- **题目错误 / 解析争议** → 开 [Issue](https://github.com/awuawuheiyohei/CCIE-HCIE_Jarvis/issues) 用 `.github/ISSUE_TEMPLATE/bug.md` 模板
- **新题收录申请** → 开 [Issue](https://github.com/awuawuheiyohei/CCIE-HCIE_Jarvis/issues) 用 `.github/ISSUE_TEMPLATE/question.md` 模板
- **备考经验 / 心得** → 在本 **Discussions** 里发贴
- **想贡献内容** → 直接发 [PR](https://github.com/awuawuheiyohei/CCIE-HCIE_Jarvis/pulls)

---

## ⭐ 如果觉得有用

右上角点个 ⭐ Star，这是对项目最大的支持。

也欢迎转发给一起备考 CCIE / HCIE 的朋友——这个项目的核心是"开源共建"，越多人的反馈，资料就越准。

---

**一起加油，拿证 🎉**

— @awuawuheiyohei

## 正文（到这里结束复制）

---

## 📝 发布步骤

1. 打开 https://github.com/awuawuheiyohei/CCIE-HCIE_Jarvis/discussions
2. 点击 **"New discussion"** 按钮
3. 分类选 **📣 Announcements**
4. 标题填：`📌 仓库使用说明 + 贡献者欢迎帖`
5. 粘正文到编辑框
6. 右侧面板点 **"Publish"**
7. 发布后，点开帖子右上角 `···` → **"Pin discussion"** 置顶

> ⚠️ 提示：markdown 里的相对路径（如 `docs/...`）在 Discussions 里点不开，**要改成完整 URL**（`https://github.com/awuawuheiyohei/CCIE-HCIE_Jarvis/blob/main/docs/...`）。我已经帮你转好了。
