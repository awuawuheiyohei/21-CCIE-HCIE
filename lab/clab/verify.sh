#!/bin/bash
# verify.sh - 自动验证 OSPF 多区域连通性
# 对应 HCIE-RS-L-2024-001 题目（lab/ensp/ 是同一拓扑的 Huawei 版本）

set -e

LAB_NAME="ccie-hcie-ospf-multi-area"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 计数器
PASS=0
FAIL=0

# 容器名映射
R1="clab-${LAB_NAME}-R1"
R2="clab-${LAB_NAME}-R2"
R3="clab-${LAB_NAME}-R3"
HOST="clab-${LAB_NAME}-host1"

# 检查容器是否存在
echo "=== 检查 lab 状态 ==="
if ! docker ps --format '{{.Names}}' | grep -q "$R1"; then
    echo -e "${RED}❌ $R1 容器没运行。先跑: cd lab/clab && sudo clab deploy${NC}"
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

check "R2 has R1 and R3" \
    "docker exec $R2 vtysh -c 'show ip ospf neighbor' | grep -E '10.0.12.1|10.0.23.3' | wc -l" \
    "2"

check "R3 has R2 as neighbor" \
    "docker exec $R3 vtysh -c 'show ip ospf neighbor' | grep Full | grep '10.0.23.2'" \
    "10.0.23.2"

echo ""
echo "=== 2. 路由学习（跨区域）==="
check "R1 learned R3's loopback (3.3.3.3) via OSPF" \
    "docker exec $R1 vtysh -c 'show ip route 3.3.3.3'" \
    "ospf"

check "R1 learned host1 network (10.0.34.0/30)" \
    "docker exec $R1 vtysh -c 'show ip route 10.0.34.0'" \
    "ospf"

check "R3 learned R1's loopback (1.1.1.1) via OSPF" \
    "docker exec $R3 vtysh -c 'show ip route 1.1.1.1'" \
    "ospf"

echo ""
echo "=== 3. 跨区域连通性 ==="
check "R1 can ping R3's loopback" \
    "docker exec $R1 ping -c 2 -W 2 3.3.3.3" \
    "received"

check "R1 can ping host1" \
    "docker exec $R1 ping -c 2 -W 2 10.0.34.4" \
    "received"

check "host1 can ping R1's loopback" \
    "docker exec $HOST ping -c 2 -W 2 1.1.1.1" \
    "received"

echo ""
echo "=== 4. 端到端综合测试 ==="
check "R1 → host1 端到端" \
    "docker exec $R1 ping -c 1 -W 2 10.0.34.4" \
    "received"

echo ""
echo "=============================="
echo -e "PASS: ${GREEN}$PASS${NC}  FAIL: ${RED}$FAIL${NC}"
echo "=============================="

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}❌ 有 $FAIL 项不通过${NC}"
    echo ""
    echo "💡 调试建议："
    echo "  1. 进 R1: docker exec -it $R1 bash"
    echo "  2. 看 OSPF 状态: vtysh -c 'show ip ospf'"
    echo "  3. 看接口: ip addr"
    echo "  4. 重启 lab: cd lab/clab && sudo clab destroy && sudo clab deploy"
    exit 1
fi

echo -e "${GREEN}🎉 全部通过！${NC}"
