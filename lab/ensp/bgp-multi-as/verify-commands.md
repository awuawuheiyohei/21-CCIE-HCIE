# eNSP BGP 验证命令

> 跟 lab/clab/bgp-multi-as/verify.sh 是同一套验证逻辑，eNSP 端手工跑。

## R1

```bash
# BGP 邻居
display bgp peer
# 期望：1 个邻居（2.2.2.2 = R2），State = Established

# BGP 路由表
display bgp routing-table
# 期望：
#   Network         NextHop        MED        LocalPref    Path
#   10.1.0.0/16     0.0.0.0        0          100          i
#   10.2.0.0/16     2.2.2.2        0          200          i      ← LocalPref 200 (R2 route-policy)
#   10.3.0.0/16     2.2.2.2        0          100          65020 65020 i
#   10.4.0.0/16     2.2.2.2        0          100          65020 65020 i

# 看 10.4.0.0/16 的具体属性
display bgp routing-table 10.4.0.0 16
# 期望：AS-Path = 65020 65020，LocalPref = 100（被 R2 的 route-policy 改了 inbound 10.2.0.0/16）

# 跨 AS ping
ping 4.4.4.4
# 期望：通
```

## R2 (ASBR 65010)

```bash
display bgp peer
# 期望：2 个邻居（1.1.1.1 iBGP + 10.0.23.3 eBGP）

display bgp routing-table 10.4.0.0 16
# 期望：AS-Path = 65020 i（只有一段，因为是从 eBGP 学来的）

display bgp routing-table 10.1.0.0 16
# 期望：NextHop = 0.0.0.0（本地起源）
```

## R3 (ASBR 65020)

```bash
display bgp peer
# 期望：2 个邻居（10.0.23.2 eBGP + 4.4.4.4 iBGP）

display bgp routing-table 10.2.0.0 16
# 期望：MED = 50（被 R2 的 route-policy export 改了）

display bgp routing-table 10.1.0.0 16
# 期望：AS-Path = 65010 65010 i
```

## R4

```bash
display bgp peer
# 期望：1 个邻居（3.3.3.3 = R3 iBGP）

display bgp routing-table 10.1.0.0 16
# 期望：AS-Path = 65010 65010

ping 1.1.1.1
# 期望：通
```

## 故障演练

### 邻居起不来

```bash
display bgp peer verbose
# 看协商过程
```

**常见原因**：
- AS 号写错（最常见）
- iBGP 没配 `connect-interface LoopBack0`（建不上邻居）
- 路由不可达
- ACL 阻止 TCP 179

### 路由不通

```bash
display bgp routing-table <prefix>
# 看具体路径和属性
```

### 抓包

eNSP 工具栏 → Capture → 选中链路 → Start
可以看 BGP 4 种报文：OPEN / UPDATE / KEEPALIVE / NOTIFICATION
