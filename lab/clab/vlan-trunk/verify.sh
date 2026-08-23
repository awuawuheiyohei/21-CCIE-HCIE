#!/bin/bash
# verify.sh - 验证 VLAN 隔离 + trunk 透传
# 验证目标：
#   ✅ host1 (V10) ↔ host2 (V10)      同 VLAN
#   ✅ host1 (V10) ↔ host3 (V10)      跨 trunk
#   ❌ host1 (V10) ↔ host4 (V20)      VLAN 隔离

set -e

LAB_NAME="ccie-hcie-vlan-trunk"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

# 容器名
H1="clab-${LAB_NAME}-host1"
H2="clab-${LAB_NAME}-host2"
H3="clab-${LAB_NAME}-host3"
H4="clab-${LAB_NAME}-host4"

# 检查
echo "=== 检查 lab 状态 ==="
if ! docker ps --format '{{.Names}}' | grep -q "$H1"; then
    echo -e "${RED}❌ 容器没运行：cd lab/clab/vlan-trunk && sudo clab deploy${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 容器在运行${NC}"
echo ""

# helper - 期望通的测试
check_ping_pass() {
    local name="$1"
    local from="$2"
    local to="$3"
    local ip="$4"

    echo -n "[$name] ... "
    result=$(docker exec $from ping -c 2 -W 2 $ip 2>&1 || echo "FAIL")
    if echo "$result" | grep -q "2 received"; then
        echo -e "${GREEN}✅ PASS${NC}"
        PASS=$((PASS+1))
    else
        echo -e "${RED}❌ FAIL（期望通）${NC}"
        echo "  实际输出: $result"
        FAIL=$((FAIL+1))
    fi
}

# helper - 期望不通的测试
check_ping_fail() {
    local name="$1"
    local from="$2"
    local to="$3"
    local ip="$4"

    echo -n "[$name] ... "
    result=$(docker exec $from ping -c 2 -W 2 $ip 2>&1 || echo "FAIL")
    # "Destination Host Unreachable" 或者 "100% packet loss" 都算不通
    if echo "$result" | grep -qE "(100% packet loss|Unreachable|0 received)"; then
        echo -e "${GREEN}✅ PASS（按预期不通）${NC}"
        PASS=$((PASS+1))
    else
        echo -e "${RED}❌ FAIL（期望不通，但实际通了？VLAN 隔离失效）${NC}"
        echo "  实际输出: $result"
        FAIL=$((FAIL+1))
    fi
}

echo "=== 1. 基础 IP 检查（每个 host 自己的 IP 应该在）==="
for h in $H1 $H2 $H3 $H4; do
    check_ping_pass "$h 能 ping 自己 loopback" "$h" "$h-self" "127.0.0.1" >/dev/null
done

echo ""
echo "=== 2. 同 VLAN 互通（host1 ↔ host2, VLAN 10）==="
check_ping_pass "host1 → host2 (V10 同 switch)" "$H1" "$H2" "10.10.0.12"
check_ping_pass "host2 → host1 (V10 同 switch)" "$H2" "$H1" "10.10.0.11"

echo ""
echo "=== 3. 跨 trunk 互通（host1 ↔ host3, VLAN 10）==="
check_ping_pass "host1 → host3 (V10 跨 trunk)" "$H1" "$H3" "10.10.0.13"
check_ping_pass "host3 → host1 (V10 跨 trunk)" "$H3" "$H1" "10.10.0.11"

echo ""
echo "=== 4. VLAN 隔离（V10 vs V20 应该不通）==="
check_ping_fail "host1 → host4 (V10 → V20 应该不通)" "$H1" "$H4" "10.20.0.14"
check_ping_fail "host4 → host1 (V20 → V10 应该不通)" "$H4" "$H1" "10.10.0.11"
check_ping_fail "host3 → host4 (V10 → V20 应该不通)" "$H3" "$H4" "10.20.0.14"
check_ping_fail "host2 → host4 (V10 → V20 应该不通)" "$H2" "$H4" "10.20.0.14"

echo ""
echo "=============================="
echo -e "PASS: ${GREEN}$PASS${NC}  FAIL: ${RED}$FAIL${NC}"
echo "=============================="

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}❌ 有 $FAIL 项不通过${NC}"
    echo ""
    echo "💡 调试："
    echo "  1. 进 SW1 看 bridge: docker exec -it clab-${LAB_NAME}-SW1 bash"
    echo "  2. 看 VLAN 配置: bridge vlan show"
    echo "  3. 重启: cd lab/clab/vlan-trunk && sudo clab destroy && sudo clab deploy"
    exit 1
fi

echo -e "${GREEN}🎉 全部通过！VLAN 隔离 + trunk 透传都正确${NC}"
