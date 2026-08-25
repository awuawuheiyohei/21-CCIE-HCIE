#!/bin/bash
# verify.sh - 验证 OSPF Stub Area 特性
# 对应知识：exams/HCIE-RS/written/ + 文档 LAB-OPERATIONS §known issues
#
# 验证 5 个关键点：
#   1. OSPF 邻居建立（R1↔R2, R2↔R3）
#   2. R1 RIB 有 10.99.0.0/16 (E2 — 从 redistribute 来的 Type 5)
#   3. R3 RIB **没有** 10.99.0.0/16 (stub 拦截 Type 5)
#   4. R3 RIB 有 0.0.0.0/0 默认路由 (ABR 注入，totally stubby 标志)
#   5. R3 仍能 ping 10.99.0.0/16 (走默认路由)

set -e

LAB_NAME="ccie-hcie-ospf-stub-area"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

R1="clab-${LAB_NAME}-R1"
R2="clab-${LAB_NAME}-R2"
R3="clab-${LAB_NAME}-R3"
HOST="clab-${LAB_NAME}-host1"

# 检查容器
echo "=== 检查 lab 状态 ==="
if ! docker ps --format '{{.Names}}' | grep -q "$R1"; then
    echo -e "${RED}❌ 容器没运行：cd lab/clab/ospf-stub-area && sudo clab deploy${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 容器在运行${NC}"
echo ""

# helper function
check() {
    local name="$1"
    local cmd="$2"
    local expected="$3"

    echo -n "[$name] ... "
    result=$(eval "$cmd" 2>&1 || echo "FAIL")
    if echo "$result" | grep -q "$expected"; then
        echo -e "${GREEN}✅ PASS${NC}"
        PASS=$((PASS+1))
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "  期望看到: $expected"
        echo "  实际输出: $result"
        FAIL=$((FAIL+1))
    fi
}

echo "=== 1. OSPF 邻居建立 ==="
check "R1 has R2 as neighbor" \
    "docker exec $R1 vtysh -c 'show ip ospf neighbor' | grep Full | grep '10.0.12.2'" \
    "10.0.12.2"

check "R2 has R1 (Area 0) and R3 (Area 1 stub)" \
    "docker exec $R2 vtysh -c 'show ip ospf neighbor' | grep -E '10.0.12.1|10.0.23.2' | wc -l" \
    "2"

check "R3 has R2 as neighbor" \
    "docker exec $R3 vtysh -c 'show ip ospf neighbor' | grep Full | grep '10.0.23.1'" \
    "10.0.23.1"

echo ""
echo "=== 2. R1 学到 external 路由（ASBR 注入）==="
check "R1 RIB 有 10.99.0.0/16 (E2 from redistribute)" \
    "docker exec $R1 vtysh -c 'show ip route 10.99.0.0'" \
    "E2"

echo ""
echo "=== 3. R3 路由表隔离检查（stub area 核心）==="
check "R3 RIB 没有 10.99.0.0/16 (被 stub 拦截 Type 5)" \
    "docker exec $R3 vtysh -c 'show ip route 10.99.0.0'" \
    "Network not in table"

check "R3 也没有 1.1.1.1 (Type 3 也被 no-summary 拦截)" \
    "docker exec $R3 vtysh -c 'show ip route 1.1.1.1'" \
    "Network not in table"

echo ""
echo "=== 4. R3 收到默认路由 (ABR 注入) ==="
check "R3 RIB 有 0.0.0.0/0 (totally stubby 默认路由)" \
    "docker exec $R3 vtysh -c 'show ip route 0.0.0.0'" \
    "0.0.0.0/0"

echo ""
echo "=== 5. 端到端连通性（走默认路由）==="
check "R3 can ping R1 (10.0.12.1)" \
    "docker exec $R3 ping -c 2 -W 2 10.0.12.1" \
    "received"

check "R3 can ping external 10.99.99.99 (走默认路由)" \
    "docker exec $R3 ping -c 2 -W 2 10.99.99.99" \
    "received"

check "host1 can ping R1 loopback (1.1.1.1, 走默认路由)" \
    "docker exec $HOST ping -c 2 -W 2 1.1.1.1" \
    "received"

echo ""
echo "=============================="
echo -e "PASS: ${GREEN}$PASS${NC}  FAIL: ${RED}$FAIL${NC}"
echo "=============================="

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}❌ 有 $FAIL 项不通过${NC}"
    echo ""
    echo "💡 调试建议："
    echo "  1. 进 R3: docker exec -it $R3 bash"
    echo "  2. 看 OSPF 状态: vtysh -c 'show ip ospf'"
    echo "  3. 看 R3 路由表: vtysh -c 'show ip route'"
    echo "  4. 看 R3 RIB 详细: vtysh -c 'show ip ospf database'"
    echo "  5. 重启: cd lab/clab/ospf-stub-area && sudo clab destroy && sudo clab deploy"
    exit 1
fi

echo -e "${GREEN}🎉 全部通过！Stub area 隔离特性验证成功${NC}"
