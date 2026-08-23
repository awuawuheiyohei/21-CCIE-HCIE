# eNSP VLAN 验证命令

> 跟 lab/clab/vlan-trunk/verify.sh 是同一套验证逻辑，eNSP 端手工跑。

## SW1 上

```bash
# 看 VLAN 表
display vlan
# 期望：看到 VLAN 10 和 VLAN 20

# 看端口类型
display port vlan
# 期望：
#   GE0/0/1  access  default vlan 10
#   GE0/0/2  access  default vlan 10
#   GE0/0/24 trunk   allow-pass 10,20

# 看 MAC 表（看 host 1/2 是不是学到）
display mac-address
# 期望：看到 4 个 host 的 MAC
```

## SW2 上（同 SW1）

```bash
display vlan
display port vlan
display mac-address
```

## 验证 VLAN 隔离（在 PC 上跑）

### 同 VLAN 互通（应该通）
- host1 → host2：`ping 10.10.0.12` ✅
- host1 → host3：`ping 10.10.0.13` ✅（跨 trunk）

### VLAN 隔离（应该不通）
- host1 → host4：`ping 10.20.0.14` ❌
- host2 → host4：`ping 10.20.0.14` ❌
- host3 → host4：`ping 10.20.0.14` ❌

## 故障演练

### VLAN 隔离不生效

```bash
# 检查 SW1
display port vlan
# 确认 host1 在 VLAN 10，host2 在 VLAN 10

# 检查 trunk
display port trunk
# 确认 trunk 上有 VLAN 10 和 VLAN 20
```

如果 trunk 配置错了（漏 allow-pass 20），VLAN 20 的 host 跨不过 trunk → 全不通。

### 抓 VLAN 标签

eNSP 工具栏 → Capture → 选 trunk 链路 → Start
可以看到 802.1Q tag（VLAN 10 / VLAN 20）。

## 进阶：打 Hybrid / QinQ / MUX VLAN

如果想再复杂，可以试：
- **Hybrid port**：跟 access/trunk 都不同，灵活
- **QinQ**：双层 tag（运营商场景）
- **MUX VLAN**：限制同 VLAN 内互通（安全场景）

每个都是新加 1-2 行命令。
