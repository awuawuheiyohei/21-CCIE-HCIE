# ContainerLab + FRRouting BGP 多 AS Lab

> **目的**：4 节点 2 个 AS，跑真 BGP 协议，验证 eBGP + iBGP + 路径属性操纵。
> 跟 `exams/CCIE-RS/written/2024-08-bgp-best-path.md` 题目配套。
>
> **真实度**：⭐⭐⭐⭐⭐ 真 BGP 协议，跟考试用真路由器一致。

## 拓扑

```
                AS 65010                                       AS 65020
   +-------+    iBGP    +-------+    eBGP    +-------+   iBGP    +-------+
   |  R1   |-----------|  R2   |------------|  R3   |----------|  R4   |
   |       | 10.0.12/30 |       | 10.0.23/30 |       | 10.0.34/30 |      |
   +-------+  (loopback)+-------+            +-------+  (loopback)+------+
   (通告 10.1.0.0/16)   (ASBR 65010)        (ASBR 65020)         (通告 10.4.0.0/16)
```

## 设计意图

- **R1 ↔ R2 (iBGP)**：同 AS 内部，用 Loopback 建邻居（生产环境标配）
- **R2 ↔ R3 (eBGP)**：跨 AS，用物理接口建邻居（eBGP 默认 TTL=1）
- **R3 ↔ R4 (iBGP)**：同 AS 内部，用 Loopback
- **R2 上有 route-map**：演示 LocalPref（影响入方向选路）和 MED（影响出方向选路）
- **每台路由器都 `network` 自己的网段**：让 BGP 表有内容可以传播

## 路由验证

跑起来后：
- R1 的 BGP 表里能看到 `10.4.0.0/16`，AS_PATH = `65020 65020`（R4→R3→R2 传到 R1，2 次出现）
- R4 的 BGP 表里能看到 `10.1.0.0/16`，AS_PATH = `65010 65010`
- R1 学到 R2 的 `10.2.0.0/16` 时 LocalPref=200（被 R2 的 route-map 改了）
- R3 学到 R2 的 `10.2.0.0/16` 时 MED=50

## 启动

### 前置要求
- Docker >= 20.10
- ContainerLab >= 0.45

### 启动 lab

```bash
cd lab/clab/bgp-multi-as
sudo clab deploy
```

启动后约 **5-10 秒** BGP 邻居建立。

### 验证

```bash
./verify.sh
```

预期：`PASS: 13  FAIL: 0`

### 手动操作

```bash
# 进 R1 看 BGP
docker exec -it clab-ccie-hcie-bgp-multi-as-R1 bash
vtysh
show ip bgp summary
show ip bgp
show ip bgp neighbors 2.2.2.2

# 跨 AS ping
docker exec clab-ccie-hcie-bgp-multi-as-R1 ping 4.4.4.4
```

### 清理

```bash
cd lab/clab/bgp-multi-as
sudo clab destroy
```

## 练习题

对应：
- `exams/CCIE-RS/written/2024-08-bgp-best-path.md`（BGP 12 步选路）
- `knowledge/01-routing/bgp.md`（BGP 完整知识库）

可以试：
- 在 R2 上加 **Weight**（FRR 没有 Weight，用 `ip protocol bgp route-map` + `set weight` 模拟）
- 加 **Route Reflector** 让 iBGP 不用全互联
- 加 **Confederation**（联盟）减少 iBGP 邻居数
- 在 R3 上配 **prefix-list** 过滤某些路由
- **抓 BGP 报文** 看 OPEN / UPDATE / KEEPALIVE

## 故障排查

### 邻居起不来

```bash
# R2 上看邻居
docker exec clab-ccie-hcie-bgp-multi-as-R2 vtysh -c 'show ip bgp summary'

# 看详细状态
docker exec clab-ccie-hcie-bgp-multi-as-R2 vtysh -c 'show ip bgp neighbors 10.0.23.3'
```

**常见原因**：
- AS 号写错（最常见）
- iBGP 没配 `update-source`（建不上邻居）
- 路由不可达（先 ping 一下）
- ACL 阻止 TCP 179

### 路由不通

```bash
# 看 BGP 表
docker exec clab-ccie-hcie-bgp-multi-as-R1 vtysh -c 'show ip bgp'

# 看具体路径
docker exec clab-ccie-hcie-bgp-multi-as-R1 vtysh -c 'show ip bgp 10.4.0.0/16'
```

## 进阶扩展

加：
- **AS_PATH 操纵**（prepend / filter-list）— 影响入方向选路
- **Route Reflector** — 打破 iBGP 全互联
- **Confederation** — 子 AS 减少 iBGP 邻居
- **BGP Confederation + RR** — 大规模 ISP 标配
- **eBGP 多跳**（loopback 建 eBGP 邻居）— 用于跨设备冗余
- **BGP 路由聚合**（aggregate-address）— 减少 BGP 表大小

每个扩展都是新加 route-map / neighbor 命令，1 个 commit 搞定。
