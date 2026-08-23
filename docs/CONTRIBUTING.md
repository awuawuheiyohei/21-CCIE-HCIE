# 🤝 贡献指南

> **欢迎所有备考 CCIE / HCIE 的同学一起共建！**

---

## 我能贡献什么？

| 贡献类型 | 难度 | 价值 |
|----------|------|------|
| 补充真题回忆（含解析） | ⭐⭐ | ⭐⭐⭐ |
| 修正错别字 / 解析错误 | ⭐ | ⭐⭐ |
| 补全双厂商对照表 | ⭐⭐⭐ | ⭐⭐⭐ |
| 新增 `knowledge/` 知识点 | ⭐⭐⭐ | ⭐⭐⭐ |
| 完善工具脚本 | ⭐⭐⭐ | ⭐⭐ |
| 报告 Issue / 提建议 | ⭐ | ⭐⭐ |

---

## 提交流程

### 1. Fork → Clone → Branch

```bash
# 1. Fork（网页上点 Fork 按钮）

# 2. Clone 你的 fork
git clone https://github.com/<你的用户名>/CCIE-HCIE.git
cd CCIE-HCIE

# 3. 创建分支（建议按贡献类型命名）
git checkout -b feat/add-ospf-lsa-questions
# 或
git checkout -b fix/typo-in-question-001
# 或
git checkout -b docs/update-ospf-knowledge
```

### 2. 编写内容

按 [QUESTION-FORMAT.md](./QUESTION-FORMAT.md) 规范编写。

### 3. 提交（Commit）

```bash
git add .
git commit -m "feat: 添加 OSPF LSA 专题 5 道真题"
# commit message 建议格式：
#   feat: 新增（题目 / 知识点 / 章节）
#   fix: 修正（解析 / 错别字 / 错误）
#   docs: 文档（更新 README / ROADMAP）
#   refactor: 重构（脚本 / 文件结构）
#   test: 测试

git push origin feat/add-ospf-lsa-questions
```

### 4. 开 PR

在 GitHub 网页上点 "Compare & pull request"。

PR 模板会引导你填写，**至少填**：

- 改动了哪些文件
- 添加 / 修改了什么
- source 从哪来（如果是真题）

### 5. 等待 Review

维护者会在 1-3 天内 review。可能要求改一些细节（解析不够详细、tag 写错等）。

通过后会自动合并 🎉

---

## 题目收录规则

### ✅ 收

- 官方题库（华为 / Cisco 培训教材）题目
- 网友回忆的真题（标好 source）
- 自编高质量模拟题（标 `source: 自编` + 解析完整）
- 老版本 / 新版本考纲对比

### ❌ 不收

- 盗版题库（淘宝 / 网盘资源）
- 无 source 的题目
- 解析只有"选 A"没有依据的
- 重复的题（先去搜一下有没有再提交）

### ⚠️ 灰区

- 网友回忆题：标 `source: 网络回忆（待验证）` + `status: draft`
- 待考纲确认的题：标 `status: draft`

---

## 知识库规范

`knowledge/` 下的每个技术点，建议按这个结构：

```markdown
# <技术点名称>

> 简介（一段话讲清楚是什么）

## 1. 原理

- 核心概念
- 关键机制（配图 / mermaid）
- 参考 RFC

## 2. 华为实现（NE / AR / CE 系列）

- 关键配置
- 默认行为
- 注意事项

## 3. 思科实现（IOS-XE / IOS-XR / NX-OS）

- 关键配置
- 默认行为
- 注意事项

## 4. 厂商差异对比

| 维度 | Huawei | Cisco |
|------|--------|-------|
| ... | ... | ... |

## 5. 实战配置示例

华为 + 思科完整配置 + 验证命令

## 6. 常见面试题

- Q1: ...
- A1: ...

## 7. 参考资料

- RFC 链接
- 官方文档
- 实验笔记
```

---

## 行为准则

- 🤝 友善：哪怕别人写错了，先肯定贡献再提改进
- 📚 严谨：每条结论要有依据，不要"我觉得"
- 🏷️ 规范：遵守 [TAG-SYSTEM.md](./TAG-SYSTEM.md)
- 💬 沟通：争议开 Issue 讨论，不要在 PR 里吵

---

## 联系方式

- Issue：bug / 建议 / 题目争议
- Discussion：技术讨论 / 备考经验
- Pull Request：直接贡献内容

---

## 致谢

所有贡献者都会列在 [README.md](../README.md) 致谢区。

---

*感谢你的贡献！每一个 PR 都让这个项目对后来者更有价值。*
