#!/usr/bin/env python3
"""
Lint 题目 md 文件的 YAML front matter

检查项（按 docs/QUESTION-FORMAT.md 规范）：
1. front matter 存在且格式正确
2. 必填字段：id / type / vendor / stage / source / tags
3. id 格式：HCIE-RS-W-2024-001 / CCIE-SP-L-2023-005
4. vendor 取值：Huawei / Cisco
5. stage 取值：written / lab / interview
6. type 取值：见 VALID_TYPE
7. difficulty 格式：1/5 ~ 5/5
8. status 取值：draft / verified / disputed / deprecated
9. source 不能是占位词（"网络" / "朋友分享" / "tba" 等）
10. status=verified 时必填 verified_by / verified_date

退出码：
- 0：全部通过
- 1：有错误
"""

import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("❌ 缺少 PyYAML 依赖，请运行: pip install pyyaml")
    sys.exit(2)


# 必填字段
REQUIRED = ['id', 'type', 'vendor', 'stage', 'source', 'tags']

# 合法取值
VALID_VENDOR = {'Huawei', 'Cisco'}
VALID_STAGE = {'written', 'lab', 'interview'}
VALID_TYPE = {
    'single-choice', 'multi-choice', 'true-false', 'fill-blank',
    'short-answer', 'lab', 'troubleshoot', 'case', 'interview-q'
}
VALID_STATUS = {'draft', 'verified', 'disputed', 'deprecated'}

# id 正则
ID_RE = re.compile(r'^(HCIE|CCIE)-[A-Z]+-[WLI]-\d{4}-\d{3}$')

# difficulty 正则
DIFFICULTY_RE = re.compile(r'^[1-5]/5$')

# date 正则
DATE_RE = re.compile(r'^\d{4}-\d{2}$')

# source 不能包含这些占位词
INVALID_SOURCE_TOKENS = [
    '网络', '朋友', '网友', '网上', 'internet', 'web',
    'tba', 'todo', 'unknown', 'xxx', 'null', 'none', 'n/a'
]


def parse_front_matter(path: Path) -> tuple[dict | None, str | None]:
    """解析 md 文件的 YAML front matter，返回 (meta, error)。"""
    try:
        content = path.read_text(encoding='utf-8')
    except Exception as e:
        return None, f"读取失败: {e}"

    if not content.startswith('---'):
        return None, "缺少 YAML front matter（文件必须以 --- 开头）"

    # 用 --- 分割，期望至少 3 段：['', '---\n...\n---\n', '...正文...']
    parts = content.split('---', 2)
    if len(parts) < 3:
        return None, "front matter 格式错误（缺少结束的 ---）"

    yaml_text = parts[1].strip()
    if not yaml_text:
        return None, "front matter 为空"

    try:
        meta = yaml.safe_load(yaml_text)
    except yaml.YAMLError as e:
        return None, f"YAML 解析失败: {e}"

    if not isinstance(meta, dict):
        return None, "front matter 必须是 key-value 格式（不能直接是 list 或纯文本）"

    return meta, None


def lint_one(path: Path) -> list[str]:
    """lint 单个文件，返回错误列表。"""
    errors = []

    meta, err = parse_front_matter(path)
    if err is not None:
        return [f"  {path}: {err}"]

    # 1. 必填字段
    for field in REQUIRED:
        value = meta.get(field)
        if value is None or value == '' or value == []:
            errors.append(f"  {path}: 必填字段 \"{field}\" 缺失或为空")

    # 2. id 格式
    if 'id' in meta and meta['id']:
        if not ID_RE.match(str(meta['id'])):
            errors.append(
                f"  {path}: id \"{meta['id']}\" 格式错误 "
                f"（应类似 HCIE-RS-W-2024-001 / CCIE-SP-L-2023-005）"
            )

    # 3. vendor
    if 'vendor' in meta and meta['vendor'] not in VALID_VENDOR:
        errors.append(
            f"  {path}: vendor \"{meta['vendor']}\" 非法 "
            f"（应: Huawei / Cisco）"
        )

    # 4. stage
    if 'stage' in meta and meta['stage'] not in VALID_STAGE:
        errors.append(
            f"  {path}: stage \"{meta['stage']}\" 非法 "
            f"（应: written / lab / interview）"
        )

    # 5. type
    if 'type' in meta and meta['type'] not in VALID_TYPE:
        errors.append(
            f"  {path}: type \"{meta['type']}\" 非法 "
            f"（合法值: {', '.join(sorted(VALID_TYPE))}）"
        )

    # 6. difficulty
    if 'difficulty' in meta and meta['difficulty']:
        if not DIFFICULTY_RE.match(str(meta['difficulty'])):
            errors.append(
                f"  {path}: difficulty \"{meta['difficulty']}\" 格式错误 "
                f"（应: 1/5 ~ 5/5）"
            )

    # 7. status
    if 'status' in meta and meta['status'] not in VALID_STATUS:
        errors.append(
            f"  {path}: status \"{meta['status']}\" 非法 "
            f"（应: {', '.join(sorted(VALID_STATUS))}）"
        )

    # 8. date
    if 'date' in meta and meta['date']:
        if not DATE_RE.match(str(meta['date'])):
            errors.append(
                f"  {path}: date \"{meta['date']}\" 格式错误 "
                f"（应: YYYY-MM）"
            )

    # 9. source 不能是占位
    if 'source' in meta and meta['source']:
        src_lower = str(meta['source']).lower()
        for token in INVALID_SOURCE_TOKENS:
            if token in src_lower:
                errors.append(
                    f"  {path}: source \"{meta['source']}\" 太模糊，"
                    f"必填具体来源（教材 / 论坛 / 实验 / 官方文档）"
                )
                break

    # 10. status=verified 必须有 verified_by / verified_date
    if meta.get('status') == 'verified':
        if not meta.get('verified_by'):
            errors.append(f"  {path}: status=verified 时必填 verified_by（你的 @GitHub用户名）")
        if not meta.get('verified_date'):
            errors.append(f"  {path}: status=verified 时必填 verified_date（YYYY-MM-DD）")

    # 11. tags 必须是 list 且非空
    if 'tags' in meta and meta['tags'] is not None:
        if not isinstance(meta['tags'], list):
            errors.append(f"  {path}: tags 必须是 list 格式（如 [ospf, lsa]）")
        elif len(meta['tags']) == 0:
            errors.append(f"  {path}: tags 至少 1 个")
        elif len(meta['tags']) > 8:
            errors.append(f"  {path}: tags 太多（{len(meta['tags'])} 个），建议 3-6 个")

    return errors


def main():
    root = Path('.')
    exams_dir = root / 'exams'

    if not exams_dir.exists():
        print("❌ exams/ 目录不存在")
        sys.exit(1)

    md_files = sorted(exams_dir.rglob('*.md'))

    if not md_files:
        print("ℹ️  exams/ 下没有 md 文件，跳过 lint")
        sys.exit(0)

    print(f"🔍 Lint {len(md_files)} 个题目文件...\n")

    all_errors = []
    for path in md_files:
        errors = lint_one(path)
        all_errors.extend(errors)

    # 输出文件级别的状态
    if all_errors:
        print(f"❌ Lint 发现 {len(all_errors)} 个问题：\n")
        for err in all_errors:
            print(err)
        print(f"\n💡 参考规范: docs/QUESTION-FORMAT.md")
        print(f"💡 或参考示例: exams/HCIE-RS/written/2024-07-ospf-lsa-001.md")
        sys.exit(1)
    else:
        print(f"✅ Lint 通过！共检查 {len(md_files)} 个文件")
        for path in md_files:
            print(f"   ✓ {path}")
        sys.exit(0)


if __name__ == '__main__':
    main()
