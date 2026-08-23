#!/bin/bash
# scripts/quiz.sh - 抽题 / 刷题工具
# 用法：
#   ./scripts/quiz.sh                          # 随机抽 10 题
#   ./scripts/quiz.sh --tag ospf               # 只抽 OSPF 相关的题
#   ./scripts/quiz.sh --vendor Huawei --count 60   # 抽 60 道 Huawei 题
#   ./scripts/quiz.sh --wrong-only             # 只抽错题本里的题
#
# TODO: 实现具体逻辑
# 占位脚本，方便后续补

set -e

echo "🚧 脚本占位中，待实现"
echo ""
echo "计划实现功能："
echo "  1. 解析 YAML front matter 提取题库"
echo "  2. 按 tag / vendor / difficulty 筛选"
echo "  3. 随机抽题 + 限时模式"
echo "  4. 错题本管理（自动记录错题）"
echo "  5. 进度统计（每个 tag 的正确率）"
echo ""
echo "需要的工具："
echo "  - yq (YAML 解析)"
echo "  - fzf (可选，用于交互选择)"
echo "  - bash / zsh"
echo ""
echo "需要的数据："
echo "  - 题库（exams/）"
echo "  - 错题本（scripts/.wrong-answers.json）"
