# eNSP BGP 多 AS Lab

> 跟 `lab/clab/bgp-multi-as` 完全同构（Huawei VRP 版本）。

## 拓扑

4 节点 2 AS，eBGP + iBGP，路径属性演示。

```
                AS 65010                                       AS 65020
   [R1]  --iBGP--  [R2]  --eBGP--  [R3]  --iBGP--  [R4]
   (通告 10.1.0.0/16)         (ASBR)         (ASBR)         (通告 10.4.0.0/16)
```

## 关键差异：Huawei vs FRR

| 维度 | Huawei (eNSP) | FRR (ContainerLab) |
|------|---------------|---------------------|
| 路由策略 | `route-policy` + `acl` | `route-map` |
| 引用方向 | `import` / `export` | `in` / `out` |
| LocalPref 改写 | `apply local-preference 200` | `set local-preference 200` |
| MED 改写 | `apply cost 50` | `set metric 50` |
| ACL 引用 | `if-match acl 2000` | `match ip address 2000` |

## 使用

1. 打开 eNSP
2. 拖 4 台 AR2240，连 3 根线
3. 启动所有设备
4. 按 `topology.md` 配每台设备（粘 `configs/*.cfg`）
5. 等待 30-60 秒 BGP 收敛
6. 跑 `verify-commands.md` 验证

## 跟 ContainerLab 版对照

跑完两边对照：
- 同样逻辑，不同厂商命令风格
- LocalPref 改写在 Huawei 用 `route-policy`，FRR 用 `route-map`
- eNSP 抓包工具可以直接看 BGP 报文

详见两个 README 里的"故障演练"。
