# 验证命令清单

> 跟 `lab/clab/verify.sh` 是同一套验证逻辑，只是 eNSP 端用手工跑命令。
> 跑完一遍，对照 `HCIE-RS-L-2024-001` 题目看是否一致。

## R1 上跑（用户视图）

```bash
# 1. 看 OSPF 邻居
display ospf peer brief
# 期望：看到 1 个邻居（10.0.12.2 = R2），State = Full

# 2. 看路由表
display ip routing-table
# 期望看到以下路由：
#   10.0.12.0/30  Direct
#   1.1.1.1/32    Direct
#   2.2.2.2/32    OSPF
#   10.0.23.0/30  OSPF
#   3.3.3.3/32    OSPF
#   10.0.34.0/30  OSPF

# 3. 跨区域 ping
ping 3.3.3.3
# 期望：通

ping 10.0.34.4
# 期望：通
```

## R2 上跑（ABR 视图）

```bash
# 1. 看 OSPF 邻居（应该 2 个）
display ospf peer brief
# 期望：R1（Area 0）+ R3（Area 1）

# 2. 看 LSDB（应该看到 Type-3 LSA = 区域间）
display ospf lsdb
# 期望：看到 Type-3 LSA

# 3. 看自己的类型
display ospf brief
# 期望：自己的角色是 ABR
```

## R3 上跑

```bash
# 1. 看 OSPF 邻居
display ospf peer brief
# 期望：R2（10.0.23.2），State = Full

# 2. 看路由
display ip routing-table
# 期望看到：
#   10.0.23.0/30  Direct
#   10.0.34.0/30  Direct
#   3.3.3.3/32    Direct
#   1.1.1.1/32    OSPF（跨区域）
#   2.2.2.2/32    OSPF
#   10.0.12.0/30  OSPF（跨区域）

# 3. 跨区域 ping
ping 1.1.1.1
# 期望：通
```

## PC1 上跑

```bash
# 1. ping R1 的 loopback
ping 1.1.1.1
# 期望：通（说明跨区域 + 跨多层都正常）

# 2. ping R3
ping 10.0.23.3
# 期望：通
```

## 进阶：故障演练

### 场景 1：邻居起不来
```bash
# 在 R2 上改错区域
[R2]interface GigabitEthernet0/0/0
[R2-GigabitEthernet0/0/0]ospf 1 area 0.0.0.5
# 然后在 R1 上看
[R1]display ospf peer
# 邻居消失，状态卡在 Down / Init
```

### 场景 2：路由学不到
```bash
# 把 R2 的 ABR 改成非 ABR（错误）
# 把 R2.GE0/0/0 移到错误的 area
# 在 R1 上看
[R1]display ip routing-table
# 应该看不到 R3 的路由（因为没 ABR 在两个区域之间传递 Type-3 LSA）
```

### 场景 3：抓包
```bash
# 在 eNSP 工具栏的 "Capture" 里抓 OSPF 报文
# 看 Hello / DD / LSR / LSU / LSAck 5 种报文
```

## 跟题目对应

跑通这个 lab 后，回头看：

- `exams/HCIE-RS/lab/2024-08-ospf-multi-area.md`（**完全同构**）
- `knowledge/01-routing/ospf.md`（OSPF 知识库）

你应该能：
- 看懂题目里"为什么 R3 路由表里看到默认路由"
- 理解 ABR 的角色
- 抓包分析 OSPF 邻居建立过程
