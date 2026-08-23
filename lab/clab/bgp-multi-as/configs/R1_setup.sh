#!/bin/bash
# R1 - 配 IP（FRR 配置已写接口 IP，loopback 用额外命令）
sleep 2
ip link set lo up
echo "R1 ready"
