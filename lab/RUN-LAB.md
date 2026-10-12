# 🏃 在本地跑这些 lab（5 分钟上手指南）

> 这份指南帮你**第一次**跑起来 ContainerLab 的 lab。
> macOS / Linux 都适用（Windows 需要 WSL2）。

## 前置检查（5 分钟）

```bash
# 1. Docker
docker --version
# 期望：Docker version 20.10+ （Docker Desktop 或 OrbStack 都行）

# 没装？
brew install --cask docker     # macOS Docker Desktop
# 或 brew install orbstack      # macOS 更轻量

# 2. ContainerLab
sudo clab version
# 期望：containerlab version 0.45.0+

# 没装？
brew install containerlab     # macOS
# 或
bash -c "$(curl -sL https://get-containerlab.dev)"   # Linux
```

## 3 步跑第一个 lab（OSPF）

```bash
# 1. 进项目目录
cd /Users/jiangwenrui/Downloads/mass/21-CCIE-HCIE/lab/clab

# 2. 部署（首次会拉 frrouting/frr 镜像，~100MB）
sudo clab deploy
# 等 30-60 秒，看到 "Containerlab started" 字样

# 3. 验证
./verify.sh
# 期望：🎉 全部通过！
```

## 跑其他 2 个 lab

```bash
# 清理
sudo clab destroy

# BGP
cd ../bgp-multi-as
sudo clab deploy
./verify.sh

# VLAN
cd ../vlan-trunk
sudo clab deploy
./verify.sh

# 清理
sudo clab destroy
```

## 出问题了？

### Docker 没起来
```bash
# macOS
open -a Docker        # 等 30 秒
docker ps             # 不报错就行
```

### clab 报"权限不够"
```bash
sudo chown -R $USER /var/run/docker.sock
# 或每次用 sudo clab deploy
```

### verify.sh 失败
```bash
# 看具体哪个节点有问题
sudo clab inspect     # 看所有节点状态
docker exec -it clab-XXX-R1 bash   # 进 R1 排障
vtysh                  # 在容器里进 FRR
show ip ospf          # 看 OSPF 状态
```

### 镜像下载慢
```bash
# 用国内 mirror
docker pull frrouting/frr:latest --registry-mirror=https://docker.mirrors.ustc.edu.cn
```

## 跑完之后？

回看 `docs/QUESTION-FORMAT.md` 里的题目，在 lab 里**复现**那些场景：
- 把 R2 改成 Stub 区域，看 R3 路由表变化
- 故意把 R1 区域 ID 写错，看 OSPF 邻居建立失败
- 在 BGP lab 里加 prefix-list 过滤路由
- 在 VLAN lab 里把 host1 加到 VLAN 20，看能不能 ping 通 host4

**这些"故意搞坏再修好"的操作比单纯跑通更能学到东西。**

## 跟项目结合

每个 lab 跟 `exams/` 和 `knowledge/` 是配套的：

| Lab | 对应题目 | 对应知识库 |
|-----|---------|-----------|
| OSPF 多区域 | HCIE-RS-L-2024-001 | knowledge/01-routing/ospf.md |
| BGP 多 AS | CCIE-RS-W-2024-001 | knowledge/01-routing/bgp.md |
| VLAN + Trunk | （暂无题目，待补） | （待补） |

跑完 lab 之后，再去做对应题目，会发现"答案突然变得直观了"。
