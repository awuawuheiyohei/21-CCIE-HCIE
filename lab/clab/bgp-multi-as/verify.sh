#!/bin/bash
# verify.sh - 自动验证 BGP 多 AS
# 对应 knowledge/01-routing/bgp.md + exams/CCIE-RS/written/2024-08-bgp-best-path.md

set -e

LAB_NAME="ccie-hcie-bgp-multi-as"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

R1="clab-${LAB_NAME}-R1"
R2="clab-${LAB_NAME}-R2"
R3="clab-${LAB_NAME}-R3"
R4="clab-${LAB_NAME}-R4"

# 检查容器
echo "=== 检查 lab 状态 ==="
if ! docker ps --format '{{.Names}}' | grep -q "$R1"; then
    echo -e "${RED}❌ 容器没运行：cd lab/clab/bgp-multi-as && sudo clab deploy${NC}"
    exit 1
fi
echo -e "${GREEN}✅ 容器在运行${NC}"
echo ""

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

echo "=== 1. BGP 邻居建立 ==="
check "R1 has R2 as iBGP neighbor (Established)" \
    "docker exec $R1 vtysh -c 'show ip bgp summary' | grep '2.2.2.2'" \
    "2.2.2.2"

check "R2 has R1 (iBGP) and R3 (eBGP)" \
    "docker exec $R2 vtysh -c 'show ip bgp summary'" \
    "1.1.1.1"

check "R3 has R2 (eBGP) and R4 (iBGP)" \
    "docker exec $R3 vtysh -c 'show ip bgp summary'" \
    "10.0.23.1"

check "R4 has R3 as iBGP neighbor" \
    "docker exec $R4 vtysh -c 'show ip bgp summary' | grep '3.3.3.3'" \
    "3.3.3.3"

echo ""
echo "=== 2. 路由学习（跨 AS）==="
check "R1 learned R4's network (10.4.0.0/16) via BGP" \
    "docker exec $R1 vtysh -c 'show ip route 10.4.0.0'" \
    "bgp"

check "R1 BGP path to 10.4.0.0/16 has AS_PATH 65020 65020 (iBGP + eBGP)" \
    "docker exec $R1 vtysh -c 'show ip bgp 10.4.0.0/16'" \
    "65020 65020"

check "R4 learned R1's network (10.1.0.0/16) via BGP" \
    "docker exec $R4 vtysh -c 'show ip route 10.1.0.0'" \
    "bgp"

check "R4 BGP path to 10.1.0.0/16 has AS_PATH 65010 65010" \
    "docker exec $R4 vtysh -c 'show ip bgp 10.1.0.0/16'" \
    "65010 65010"

echo ""
echo "=== 3. 跨 AS 连通性 ==="
# 等 OSPF 没有，但有直连路由
check "R1 can ping R2" \
    "docker exec $R1 ping -c 2 -W 2 2.2.2.2" \
    "received"

check "R2 can ping R3 (eBGP link)" \
    "docker exec $R2 ping -c 2 -W 2 10.0.23.2" \
    "received"

check "R1 can ping R4 (BGP learned)" \
    "docker exec $R1 ping -c 2 -W 2 4.4.4.4" \
    "received"

echo ""
echo "=== 4. 路径属性验证 ==="
check "R1 sees 10.2.0.0/16 with LocalPref 200 (via R2 route-map)" \
    "docker exec $R1 vtysh -c 'show ip bgp 10.2.0.0/16'" \
    "200"

check "R3 sees 10.2.0.0/16 with MED 50 (R2 export route-map)" \
    "docker exec $R3 vtysh -c 'show ip bgp 10.2.0.0/16'" \
    "50"

echo ""
echo "=============================="
echo -e "PASS: ${GREEN}$PASS${NC}  FAIL: ${RED}$FAIL${NC}"
echo "=============================="

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}❌ 有 $FAIL 项不通过${NC}"
    echo ""
    echo "💡 调试建议："
    echo "  1. 进 R1: docker exec -it $R1 bash"
    echo "  2. 看 BGP 状态: vtysh -c 'show ip bgp summary'"
    echo "  3. 看邻居详细: vtysh -c 'show ip bgp neighbors 2.2.2.2'"
    echo "  4. 重启: cd lab/clab/bgp-multi-as && sudo clab destroy && sudo clab deploy"
    exit 1
fi

echo -e "${GREEN}🎉 全部通过！${NC}"
