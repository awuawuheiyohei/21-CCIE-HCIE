# ContainerLab + FRRouting OSPF 多区域 Lab

> **目的**：用真实路由协议（FRRouting，开源 Cisco-like）在容器里跑 OSPF 多区域 + ABR，
> 跟 `exams/HCIE-RS/lab/2024-08-ospf-multi-area.md` 题目**完全同构**，方便对照练习。
>
> **真实度**：⭐⭐⭐⭐⭐ 真协议真交互，不是 CLI 模拟。

## 拓扑

```
       [Area 0]              [Area 1]
  R1 --- 10.0.12.0/30 --- R2 --- 10.0.23.0/30 --- R3
                                  (ABR)           |
                                                 | 10.0.34.0/30
                                                 v
                                              host1
                              (test PC, 验证跨区域连通性)
```

## 前置要求

| 软件 | 版本 | 用途 |
|------|------|------|
| **Docker** | >= 20.10 | 跑容器 |
| **ContainerLab** | >= 0.45 | 编排容器网络 |
| **bash / zsh** | - | 跑脚本 |

### 安装

```bash
# macOS
brew install docker    # 或装 Docker Desktop
brew install containerlab

# Linux
# Docker: https://docs.docker.com/engine/install/
# ContainerLab: bash -c "$(curl -sL https://get-containerlab.dev)"
```

## 使用步骤

### 1. 启动 lab

```bash
cd lab/clab
sudo clab deploy
```

启动后会自动 pull `frrouting/frr:latest` 镜像（约 100MB）和 `alpine:latest`（约 5MB）。

### 2. 等待 OSPF 收敛

启动后约 **5-10 秒** OSPF 邻居建立完成。期间 R1 的 ping 可能不通，等收敛完就好了。

### 3. 验证

```bash
./verify.sh
```

预期输出：`PASS: 10  FAIL: 0`，最后一行 `🎉 全部通过！`

### 4. 手动操作

```bash
# 进 R1 看 OSPF 状态
docker exec -it clab-ccie-hcie-ospf-multi-area-R1 bash
vtysh
show ip ospf
show ip ospf neighbor
show ip route

# 从 R1 ping R3
docker exec clab-ccie-hcie-ospf-multi-area-R1 ping 3.3.3.3

# 抓包看 OSPF 报文（如果有 tcpdump）
docker exec clab-ccie-hcie-ospf-multi-area-R1 tcpdump -i R1-eth1 -n ospf
```

### 5. 清理

```bash
cd lab/clab
sudo clab destroy
```

## 练习题

把这个 lab 当**实操**环境，对应以下题目：

1. **HCIE-RS-L-2024-001**（OSPF 多区域 + Stub + 汇总）
2. **CCIE-RS-L 对应题**（同等拓扑，OSPF multi-area）

你可以试：
- 在 R2 上配 `abr-summary` 汇总 Area 0 路由
- 把 R3 改成 Stub 区域
- 抓 OSPF Hello 包看 TTL / Area ID / 邻居列表
- 故意配错（如 R2 区域 ID 写错），看邻居建立失败信息

## 与 eNSP 版的差异

| 维度 | ContainerLab（这） | eNSP |
|------|-------------------|------|
| 镜像 | FRRouting（开源） | Huawei AR2240（专有） |
| 命令风格 | `vtysh`（Cisco IOS 风格） | 华为 VRP |
| 启动速度 | 快（容器秒级） | 慢（镜像启动 30-60s） |
| 依赖 | Docker | VirtualBox + eNSP |
| 真协议 | ✅ 是 | ✅ 是 |
| 资源占用 | 低 | 中（VirtualBox 占用） |
| 适合 | 协议行为学习 | 华为特性 / 面试模拟 |

**两个都做同一拓扑**，方便你对照"同一逻辑不同厂商实现"。

## 故障排查

### 容器起不来
```bash
sudo clab deploy --reconfigure
# 或者
docker logs clab-ccie-hcie-ospf-multi-area-R1
```

### OSPF 邻居起不来
```bash
docker exec clab-ccie-hcie-ospf-multi-area-R1 vtysh -c 'show ip ospf'
docker exec clab-ccie-hcie-ospf-multi-area-R1 vtysh -c 'show ip ospf neighbor'
```

常见原因：
- 接口没起来：`ip link show`
- 区域 ID 不一致
- Hello / Dead 间隔不一致

### ping 不通
```bash
# 看路由
docker exec ... vtysh -c 'show ip route <目标 IP>'

# 抓包
docker exec ... tcpdump -i R1-eth1 -n
```

## 进阶：扩展这个 lab

可以加：
- **BGP** 邻居（外部 AS 连接）
- **IS-IS**（替代 OSPF）
- **MPLS**（运营商特性）
- **IPv6**（OSPFv3）
- **VRRP**（网关冗余）

每个扩展都是新写一个 frr.conf + topology.clab.yml 即可。
