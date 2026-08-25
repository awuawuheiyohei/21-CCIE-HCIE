# Lab Operations Manual

> How to run and verify the 3 CCIE/HCIE labs in this repo on macOS M1 + Docker Desktop.
> Last validated: 2026-08-25 (3 labs, 35 verify.sh checks, all PASS).

## Labs overview

| Lab | Directory | What it demonstrates | verify.sh |
|---|---|---|---|
| **OSPF multi-area** | `lab/clab/ospf-multi-area/` | 3-router ABR (R1↔R2 ABR↔R3 + host1), Areas 0/1, ABR self-summary bug workaround | 10/10 ✅ |
| **BGP multi-AS** | `lab/clab/bgp-multi-as/` | 2 ASes (65010 / 65020), 4 routers, eBGP + iBGP, route-map (LocalPref / MED), next-hop-self | 13/13 ✅ |
| **VLAN / trunk** | `lab/clab/vlan-trunk/` | 2 switches + 4 hosts, access port (untagged) + trunk (tagged), VLAN 10 + VLAN 20 isolation | 12/12 ✅ |

## Prerequisites

1. **macOS M1 with Docker Desktop** (linux/arm64 host)
2. **clab wrapper installed** at `/usr/local/bin/clab` (uses `ghcr.io/srl-labs/clab:0.55.0`):
   ```bash
   # /usr/local/bin/clab — must be installed, sudo not needed to write file but sudo is required for first-time
   docker run --rm -it --privileged \
     --network host \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -v /var/run/netns:/var/run/netns \
     -v /etc/hosts:/etc/hosts \
     -v /var/lib/docker/containers:/var/lib/docker/containers \
     --pid="host" \
     -v "${PWD}:${PWD}" \
     -w "${PWD}" \
     --entrypoint clab \
     ghcr.io/srl-labs/clab:0.55.0 "$@"
   ```
3. **frr image pulled**: `docker pull frrouting/frr:v8.4.1` (the v prefix is required — `:8.4.1` without v does not exist on Docker Hub)
4. **No Homebrew clab needed** — Homebrew tap for containerlab does not exist; we use Docker + shell-wrapper instead.

## Deploy + verify a lab

```bash
# 1. Go to a lab directory
cd lab/clab/<lab-name>           # e.g. ospf-multi-area

# 2. Optional: clean leftover containers (clab destroy -c can fail on /etc/hosts permission)
docker rm -f $(docker ps -aq --filter "label=clab-lab-name=<lab-name>") 2>/dev/null

# 3. Deploy
sudo clab deploy
# Expected: 4 (or 6) containers created, "Up" state, some warnings are normal:
#   - "platform (linux/amd64) does not match ... linux/arm64/v8" (qemu emulation)
#   - "iptables rules install: not available" (Docker Desktop)
#   - "lib/modules ... no such file or directory" (kernel module loader)
#   - "failed to create hosts file: open /etc/hosts: permission denied" (cosmetic)

# 4. Wait for convergence
sleep 10   # OSPF/BGP: 10-15s. VLAN: 3-5s.

# 5. Verify
./verify.sh
```

If `sudo clab deploy` complains `containers already exist` after a failed deploy, use the `docker rm -f` workaround above.

## If verify.sh fails

### Step 1: container state
```bash
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep clab-<lab>
```
All containers should be `Up`. If not, see the deploy log.

### Step 2: inside the container
```bash
docker exec -it clab-<lab>-<node> bash
ip -br addr show
ip route
vtysh -c 'show ip ospf neighbor'    # OSPF
vtysh -c 'show ip bgp summary'      # BGP
bridge vlan show                    # VLAN
```

### Step 3: known issues

The 22 bugs we hit during initial bring-up are all documented in
[memory](https://example.com) but the most likely ones you'll hit on
M1 + Docker Desktop are:

1. **"Can't open /etc/frr/vtysh.conf"** — bind an empty `vtysh.conf` per node (this repo does it for all 4 frr nodes).
2. **BGP neighbor Established but 0 prefixes cross** — see `bgp ebgp-requires-policy` (R2/R3 have `no bgp ebgp-requires-policy` in their frr.conf).
3. **OSPF: R2 RIB shows `O>r 3.3.3.3 rejected`** — frr 8.4 ABR self-summary bug; we work around it with `ip route replace 3.3.3.3/32 via 10.0.23.3` in R2_setup.sh.
4. **"2 received" not found in ping output** — verify.sh has been updated; substring bug, not a network problem.
5. **BGP: AS_PATH missing transit AS** — frr 8.4 eBGP outbound doesn't prepend own AS (known bug, doesn't break routing).

## Tear-down

```bash
sudo clab destroy -c    # may fail on /etc/hosts — non-blocking
docker rm -f clab-<lab>-* 2>/dev/null
```

The clab runtime dir `clab-<lab>-*/` will be left behind and is in `.gitignore`.

## Key files per lab

```
lab/clab/<lab>/
├── topology.clab.yml         # node/link definitions
├── configs/                  # bind-mounted into containers
│   ├── R*_frr.conf          # frr config for that node
│   ├── R*_setup.sh          # node startup script (ip link, ip route, etc.)
│   ├── daemons              # which frr daemons to run
│   └── vtysh.conf           # required for vtysh to work (don't skip!)
├── verify.sh                 # run this; prints PASS/FAIL per check
└── README.md                 # lab-specific notes
```

## Adding a new lab

1. Copy an existing lab dir as a template.
2. Update `name:`, `topology.nodes`, `topology.links`.
3. Add `configs/vtysh.conf` to every node that runs frr.
4. For each router that has a loopback reachable only via another router's
   physical IP, add `ip route <lo> <physical>` in frr.conf (not in setup.sh —
   frr zebra wipes kernel static routes on startup).
5. For each `network X.X.X.X/Y` in BGP, also add `ip route X.X.X.X/Y Null0`
   (frr's `network` command requires an exact-match RIB entry).
6. For each eBGP neighbor, add `no bgp ebgp-requires-policy` in router bgp,
   OR define a route-map/filter-list for the outbound direction. Without this,
   frr 8.4 silently drops all outbound UPDATEs.
7. Use `interface eth1` (not `<node>-eth1`) in frr.conf — clab 0.55 uses
   bare ethN names.
8. Write `verify.sh` with the same `check()` helper as other labs (see
   any existing lab for template).
9. Add the lab dir to this manual's overview table.
