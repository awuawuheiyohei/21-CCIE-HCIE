#!/bin/bash
# SW2 - 第二台 switch
# 端口分配：
#   eth1 → host3 (VLAN 10 access)
#   eth2 → host4 (VLAN 20 access)
#   eth3 → SW1 (trunk, 允许 VLAN 10, 20)

set -e

for i in 1 2 3 4 5; do
  if ip link show eth1 >/dev/null 2>&1 && ip link show eth2 >/dev/null 2>&1 && ip link show eth3 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

ip link add br0 type bridge
ip link set br0 up

ip link add link br0 name br0.10 type vlan id 10
ip link add link br0 name br0.20 type vlan id 20
ip link set br0.10 up
ip link set br0.20 up

# eth1 - VLAN 10 access
ip link add link eth1 name eth1.10 type vlan id 10
ip link set eth1.10 master br0
ip link set eth1.10 up
ip link set eth1 master br0
ip link set eth1 up
bridge vlan add dev eth1 vid 10 pvid untagged

# eth2 - VLAN 20 access
ip link add link eth2 name eth2.20 type vlan id 20
ip link set eth2.20 master br0
ip link set eth2.20 up
ip link set eth2 master br0
ip link set eth2 up
bridge vlan add dev eth2 vid 20 pvid untagged

# eth3 - trunk
ip link set eth3 master br0
ip link set eth3 up
bridge vlan add dev eth3 vid 10
bridge vlan add dev eth3 vid 20

echo "SW2 ready: 1 access (VLAN 10) + 1 access (VLAN 20) + 1 trunk"
bridge vlan show
