# 🌐 Amazon VPC — Study Notes

> *Wednesday, April 08, 2026*

---

## Table of Contents

- [Introduction](#introduction)
- [VPC Fundamentals](#vpc-fundamentals)
- [CIDR Blocks and IP Addressing](#cidr-blocks-and-ip-addressing)
- [Subnets](#subnets)
- [Route Tables](#route-tables)
- [Internet Gateway (IGW)](#internet-gateway-igw)
- [NAT Gateway and NAT Instance](#nat-gateway-and-nat-instance)
- [Security Groups](#security-groups)
- [Network Access Control Lists (NACLs)](#network-access-control-lists-nacls)
- [Security Groups vs NACLs](#security-groups-vs-nacls)
- [VPC Peering](#vpc-peering)
- [Transit Gateway](#transit-gateway)
- [VPC Endpoints](#vpc-endpoints)
- [VPC Flow Logs](#vpc-flow-logs)
- [DNS in VPC](#dns-in-vpc)
- [Elastic Network Interfaces (ENIs)](#elastic-network-interfaces-enis)
- [IPv6 in VPC](#ipv6-in-vpc)
- [Network Monitoring and Troubleshooting](#network-monitoring-and-troubleshooting)
- [Tips & Best Practices](#tips--best-practices)
- [Pitfalls & Remedies](#pitfalls--remedies)
- [Summary](#summary)
- [Hands-On Lab Exercise](#hands-on-lab-exercise)

---

## Introduction

Amazon Virtual Private Cloud (VPC) is the **networking foundation** of your AWS infrastructure. It provides isolated network environments where you can launch AWS resources with complete control over:

- IP addressing
- Subnets
- Route tables
- Network gateways

> 💡 **Analogy:** Think of VPC as your private data center in the cloud — with the flexibility and scalability that traditional networking could never provide.

**Key capabilities:**
- Create multiple isolated networks within a single AWS account
- Segment into public and private subnets
- Control traffic flow with security groups and network ACLs
- Connect to on-premises networks through VPN or Direct Connect

### Why Proper VPC Design Matters

| Good Design ✅ | Poor Design ❌ |
|---|---|
| Security through network isolation | IP address exhaustion |
| High availability via multi-AZ | Complex, fragile routing |
| Hybrid cloud connectivity | Security vulnerabilities |
| Scalable for future growth | Costly re-architecture |

---

## VPC Fundamentals

A VPC is a **logically isolated section** of the AWS Cloud where you can launch resources in a virtual network that you define. Each VPC exists within a single AWS Region but can span multiple Availability Zones.

### Key Characteristics

| Property | Details |
|---|---|
| **Scope** | Region-specific; cannot span multiple regions |
| **AZ Support** | Subnets can be distributed across AZs |
| **IP Control** | You define the IP address range using CIDR notation |
| **Default Limit** | 5 VPCs per region *(soft limit, can be increased)* |
| **Isolation** | VPCs are isolated from each other by default |

### Default VPC

Every AWS account comes with a default VPC in each region:

- **CIDR block:** `172.31.0.0/16`
- One default subnet per AZ (typically `/20`)
- Internet Gateway attached
- Default security group and network ACL

> ⚠️ Convenient for getting started, but **production workloads should use custom VPCs**.

---

## CIDR Blocks and IP Addressing

CIDR (Classless Inter-Domain Routing) notation defines IP address ranges for your VPC.

**Example:** `10.0.0.0/16`
- First part → Network address (`10.0.0.0`)
- Second part → Prefix length (16 bits for network, 16 bits for hosts)

### AWS VPC CIDR Requirements

- **Minimum:** `/28` (16 IP addresses)
- **Maximum:** `/16` (65,536 IP addresses)
- Supports **RFC 1918** private IP ranges:
  - `10.0.0.0/8` → `10.0.0.0 – 10.255.255.255`
  - `172.16.0.0/12` → `172.16.0.0 – 172.31.255.255`
  - `192.168.0.0/16` → `192.168.0.0 – 192.168.255.255`
- Can use publicly routable CIDR blocks *(not recommended)*

### CIDR Block Sizing

| CIDR | Total IPs | Usable IPs | Use Case |
|---|---|---|---|
| `/28` | 16 | 11 | Very small subnets |
| `/24` | 256 | 251 | Small subnets *(typical private subnet)* |
| `/20` | 4,096 | 4,091 | Medium subnets *(typical public subnet)* |
| `/16` | 65,536 | 65,531 | Entire VPC *(typical size)* |

### AWS Reserves 5 IPs per Subnet

**Example in `10.0.0.0/24`:**

| Address | Reserved For |
|---|---|
| `10.0.0.0` | Network address |
| `10.0.0.1` | VPC router |
| `10.0.0.2` | DNS server |
| `10.0.0.3` | Future use |
| `10.0.0.4 – 10.0.0.254` | ✅ Available (251 addresses) |
| `10.0.0.255` | Broadcast address |

### Secondary CIDR Blocks

- Add up to **5 secondary CIDR blocks** to a VPC
- Useful when you run out of IP addresses
- Must not overlap with existing CIDR blocks
- Cannot be removed if subnets are using them

---

## Subnets

Subnets are **subdivisions of a VPC's IP address range** where you launch AWS resources.

### Subnet Characteristics

| Property | Details |
|---|---|
| **AZ-Specific** | Each subnet exists in a single Availability Zone |
| **CIDR Subset** | Subnet CIDR must be within the VPC CIDR range |
| **No Overlap** | Subnets cannot have overlapping CIDR blocks |
| **Classification** | Public vs Private — based on routing, not an inherent property |

### Public Subnets

- Have a route to **Internet Gateway (IGW)**
- Resources get public IP addresses
- **Used for:** Web servers, load balancers, bastion hosts

### Private Subnets

- No direct route to IGW
- Resources use **NAT Gateway/Instance** for outbound internet
- **Used for:** Application servers, databases, internal services

### Subnet Sizing Strategy

**Example VPC: `10.0.0.0/16`**

```
Public Subnets (smaller, fewer resources):
  10.0.1.0/24  — AZ-a  (251 hosts)
  10.0.2.0/24  — AZ-b  (251 hosts)
  10.0.3.0/24  — AZ-c  (251 hosts)

Private App Subnets (medium):
  10.0.11.0/24 — AZ-a  (251 hosts)
  10.0.12.0/24 — AZ-b  (251 hosts)
  10.0.13.0/24 — AZ-c  (251 hosts)

Private Data Subnets (smaller, highly controlled):
  10.0.21.0/24 — AZ-a  (251 hosts)
  10.0.22.0/24 — AZ-b  (251 hosts)
  10.0.23.0/24 — AZ-c  (251 hosts)

Reserved for future expansion:
  10.0.100.0/22          (1,019 hosts)
  10.1.0.0/16            (entire /16 block)
```

---

## Route Tables

Route tables determine **where network traffic from subnets is directed**.

### Route Table Components

| Component | Description |
|---|---|
| **Destination** | IP address range (CIDR) |
| **Target** | Where to send matching traffic (IGW, NAT, VPC peer, etc.) |
| **Main Route Table** | Automatically created with VPC, used by default |
| **Custom Route Tables** | Created for specific routing requirements |

### Default Local Route

Every route table has an immutable local route:

```
Destination: 10.0.0.0/16  →  Target: local
```

> ⚠️ This route **cannot be modified or deleted**.

### Route Priority

AWS uses the **most specific route** (longest prefix match):

```
10.0.0.0/16   → local
10.0.1.0/24   → NAT Gateway
10.0.1.15/32  → VPN         ← Traffic to 10.0.1.15 uses THIS route
```

### Route Table Types

**Public Route Table:**
```
Destination    Target
10.0.0.0/16    local
0.0.0.0/0      igw-xxxxx
```

**Private Route Table:**
```
Destination    Target
10.0.0.0/16    local
0.0.0.0/0      nat-xxxxx
```

**Isolated Route Table (no internet):**
```
Destination      Target
10.0.0.0/16      local
192.168.0.0/16   vgw-xxxxx  (VPN to on-premises)
```

---

## Internet Gateway (IGW)

An Internet Gateway enables **communication between VPC resources and the internet**.

### IGW Characteristics

| Property | Details |
|---|---|
| **Availability** | Redundant and horizontally scaled by AWS |
| **Bandwidth** | Scales automatically — no constraints |
| **Limit** | One IGW per VPC |
| **Direction** | Bidirectional (inbound + outbound) |
| **State** | Stateless — doesn't track connections |

### Requirements for Internet Access

1. Attach IGW to VPC
2. Create route to IGW (`0.0.0.0/0 → igw-xxxxx`)
3. Assign public IP or Elastic IP to resources
4. Security Group must allow outbound traffic
5. Network ACL must allow traffic

### Public IP vs Elastic IP

| Feature | Public IP | Elastic IP (EIP) |
|---|---|---|
| Assignment | Auto-assigned | Manually allocated |
| Persistence | Changes on stop/start | Persists across stops/starts |
| Portability | Cannot be moved | Can be reassigned |
| Cost | Free | Charged when unassociated |
| Use Case | General instances | NAT gateways, bastion hosts, whitelisting |

---

## NAT Gateway and NAT Instance

NAT (Network Address Translation) enables **instances in private subnets to connect to the internet** while preventing inbound connections.

### NAT Gateway (AWS Managed)

| Property | Details |
|---|---|
| **Management** | Fully managed by AWS |
| **Availability** | Highly available within a single AZ |
| **Throughput** | Scales automatically up to 45 Gbps |
| **Connections** | Up to 55,000 simultaneous |
| **Cost** | $0.045/hr + $0.045/GB processed |

**Best Practices:**
- Deploy **one NAT Gateway per AZ** for high availability
- Place in public subnet with route to IGW
- Allocate Elastic IP for stable outbound IP

> 💰 **Free data transfer** to S3/DynamoDB in the same region via gateway endpoint.

### NAT Instance (Self-Managed)

An EC2 instance configured to perform NAT.

| Advantages | Disadvantages |
|---|---|
| Lower cost (EC2 pricing only) | Manual management required |
| Can serve as bastion host | Single point of failure |
| Full software control | Limited bandwidth (instance-dependent) |
| | Must disable source/destination check |

### When to Use

| Scenario | Choice |
|---|---|
| Production workloads, HA required | **NAT Gateway** |
| Cost-sensitive, need extra functionality | **NAT Instance** |

---

## Security Groups

Security groups act as **virtual firewalls at the instance level** (ENI).

### Key Characteristics

| Property | Details |
|---|---|
| **Stateful** | Return traffic automatically allowed |
| **Level** | Applied to ENIs (Elastic Network Interfaces) |
| **Default** | All inbound denied; all outbound allowed |
| **Rules** | Allow-only — cannot explicitly deny |
| **Limit** | Up to 5 security groups per instance |
| **Changes** | Take effect immediately |

### Example Rules

**Inbound:**

| Type | Protocol | Port | Source |
|---|---|---|---|
| HTTP | TCP | 80 | `0.0.0.0/0` |
| HTTPS | TCP | 443 | `0.0.0.0/0` |
| SSH | TCP | 22 | `203.0.113.0/24` *(office network)* |
| MySQL | TCP | 3306 | `sg-12345678` *(app server SG)* |

### Security Group Chaining

Reference other security groups instead of hardcoding IPs:

```
Web Server SG   → Inbound: Port 80/443 from 0.0.0.0/0
App Server SG   → Inbound: Port 8080 from Web Server SG
Database SG     → Inbound: Port 3306 from App Server SG
```

> ✅ This automatically adapts as instances are added or removed.

---

## Network Access Control Lists (NACLs)

NACLs are **stateless firewalls at the subnet level**.

### Key Characteristics

| Property | Details |
|---|---|
| **Stateful** | ❌ Stateless — return traffic must be explicitly allowed |
| **Level** | Subnet-level — applies to all resources in subnet |
| **Default** | Default NACL allows all traffic |
| **Evaluation** | Rules evaluated in numerical order (lowest first); stops at first match |
| **Explicit Deny** | ✅ Can explicitly deny traffic (unlike security groups) |

### NACL Rule Structure

Each rule has: **Rule Number** · **Type** · **Port Range** · **Source/Destination** · **Action (Allow/Deny)**

**Example NACL:**

```
Inbound Rules:
Rule #   Type    Protocol  Port       Source            Allow/Deny
100      HTTP    TCP       80         0.0.0.0/0         Allow
110      HTTPS   TCP       443        0.0.0.0/0         Allow
120      SSH     TCP       22         203.0.113.0/24    Allow
130      Custom  TCP       1024-65535 0.0.0.0/0         Allow (ephemeral ports)
*        All     All       All        0.0.0.0/0         Deny

Outbound Rules:
Rule #   Type    Protocol  Port       Destination       Allow/Deny
100      HTTP    TCP       80         0.0.0.0/0         Allow
110      HTTPS   TCP       443        0.0.0.0/0         Allow
120      Custom  TCP       1024-65535 0.0.0.0/0         Allow (ephemeral ports)
*        All     All       All        0.0.0.0/0         Deny
```

### Ephemeral Ports

Because NACLs are stateless, you **must allow ephemeral ports** for return traffic:

| OS / Service | Port Range |
|---|---|
| Linux | 32768 – 61000 |
| Windows | 49152 – 65535 |
| ELB | 1024 – 65535 |
| **Recommendation** | **1024 – 65535** *(covers all)* |

---

## Security Groups vs NACLs

| Feature | Security Group | NACL |
|---|---|---|
| **Level** | Instance (ENI) | Subnet |
| **State** | Stateful | Stateless |
| **Rules** | Allow only | Allow and Deny |
| **Evaluation** | All rules | First match |
| **Default** | Deny all inbound | Allow all |
| **Return Traffic** | Automatic | Manual |

> 💡 **Best Practice:** Use security groups as the primary security layer; use NACLs for additional subnet-level protection.

---

## VPC Peering

VPC Peering creates a **networking connection between two VPCs** using private IP addresses.

### Characteristics

| Property | Details |
|---|---|
| **Transitive Routing** | ❌ Non-transitive — cannot route through intermediary |
| **CIDR Overlap** | Not allowed — connected VPCs must have distinct IP ranges |
| **Cross-Region** | ✅ Supported |
| **Cross-Account** | ✅ Supported |
| **Encryption** | ✅ Inter-region traffic is encrypted |
| **Availability** | Highly available by design |

### Transitive Routing Example

```
VPC A (10.0.0.0/16) ←→ VPC B (10.1.0.0/16) ←→ VPC C (10.2.0.0/16)

❌ VPC A CANNOT communicate with VPC C through VPC B
✅ Direct peering required: VPC A ←→ VPC C
```

### Peering Limitations

- Maximum **125 peering connections** per VPC
- No overlapping CIDR blocks
- Security groups can reference peer VPC SGs *(same region only)*

### Use Cases

- Shared services VPC (DNS, Active Directory)
- Dev/test environment access to shared resources
- Multi-region disaster recovery
- Merging networks from acquired companies

---

## Transit Gateway

AWS Transit Gateway acts as a **cloud router**, connecting multiple VPCs and on-premises networks through a central hub.

### Key Benefits

- **Simplified Topology:** Hub-and-spoke instead of full mesh
- **Transitive Routing:** Supports transitive connections *(unlike VPC peering)*
- **Scalability:** Connect thousands of VPCs
- **Cross-Region:** Inter-region peering support
- **Route Tables:** Multiple route tables for traffic segmentation
- **Multicast:** Supports multicast traffic

### Transit Gateway vs VPC Peering

**VPC Peering — Full Mesh (5 VPCs):**

Connections required: `n(n-1)/2 = 10 peering connections`

**Transit Gateway — Hub-Spoke (5 VPCs):**

Connections required: `n = 5 attachments`

```
          TGW
        / | \ \  \
  VPC1 VPC2 VPC3 VPC4 VPC5
```

### Transit Gateway Attachments

- VPC attachments
- VPN connections
- Direct Connect gateways
- Transit Gateway peering (inter-region)

### Transit Gateway Route Tables

```
Production Route Table:
  ✅ Production VPCs can talk to each other
  ✅ Can route to on-premises (VPN)
  ❌ Cannot access development VPCs

Development Route Table:
  ✅ Development VPCs can talk to each other
  ✅ Can access shared services
  ❌ Cannot access production
```

### Costs

- `$0.05` per attachment hour
- `$0.02` per GB processed

> More expensive than VPC peering but provides significantly more flexibility.

---

## VPC Endpoints

VPC Endpoints enable **private connections to AWS services** without traversing the internet.

### 1. Gateway Endpoints *(S3 and DynamoDB)*

- **Free** — no data processing charges
- Added as route table entries
- Region-specific (same-region access only)
- Policy-controlled access

```
Route table entry:
Destination                          Target
pl-12345678 (S3 prefix list)   →    vpce-xxxxx (Gateway endpoint)
```

### 2. Interface Endpoints *(PrivateLink)*

- ENI-based — creates elastic network interface in subnet
- Private DNS names resolve to private IPs
- **Cost:** `$0.01/hr + $0.01/GB` processed
- Deploy in each AZ for high availability
- Supports most AWS services (EC2, SNS, SQS, etc.)

### Benefits

- Enhanced security (no internet exposure)
- Reduced data transfer costs
- Improved performance (lower latency)
- Meet compliance requirements (data stays within AWS network)

### Use Cases

- Access S3 from private subnets without NAT
- Private API Gateway endpoints
- PrivateLink for SaaS applications
- Service-to-service communication

---

## VPC Flow Logs

VPC Flow Logs capture **information about IP traffic flowing through network interfaces**.

### Capabilities

| Property | Details |
|---|---|
| **Capture Levels** | VPC, subnet, or ENI |
| **Traffic Filter** | All, accepted only, or rejected only |
| **Destinations** | CloudWatch Logs, S3, Kinesis Data Firehose |
| **Performance** | No impact — captured outside the data path |

### Flow Log Record Format

```
version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes start end action logstatus

2 123456789012 eni-abc123 10.0.1.5 198.51.100.1 49152 80 6 10 5200 1620000000 1620000060 ACCEPT OK
```

### Use Cases

- Security analysis (identify unauthorized access)
- Troubleshooting connectivity issues
- Cost analysis (data transfer patterns)
- Compliance auditing
- Network traffic analysis

### Analysis with CloudWatch Logs Insights

```sql
fields @timestamp, srcAddr, dstAddr, srcPort, dstPort, action
| filter action = "REJECT"
| stats count(*) as rejectionCount by srcAddr
| sort rejectionCount desc
| limit 10
```

---

## DNS in VPC

Every VPC has DNS resolution provided by **Amazon Route 53 Resolver**.

### DNS Settings

| Setting | Default | Description |
|---|---|---|
| `enableDnsSupport` | `true` | DNS resolution enabled |
| `enableDnsHostnames` | Depends on VPC type | Assign public DNS hostnames |

### DNS Resolution

```
Internal:  ip-10-0-1-5.ec2.internal
Public:    ec2-198-51-100-1.compute-1.amazonaws.com
```

### Route 53 Resolver

- DNS queries routed to `VPC+2` address (e.g., `10.0.0.2`)
- Resolves internal names and forwards external queries
- Configurable forwarding rules for on-premises DNS

### Private Hosted Zones

Associate private Route 53 hosted zones with VPCs for:
- Internal DNS names (e.g., `app.internal.example.com`)
- Cross-VPC DNS resolution
- Hybrid DNS between AWS and on-premises

---

## Elastic Network Interfaces (ENIs)

An ENI is a **logical networking component** representing a virtual network card.

### ENI Attributes

- Primary private IPv4 address
- One or more secondary private IPv4 addresses
- One Elastic IP per private IPv4
- One public IPv4 *(optional)*
- One or more security groups
- MAC address
- Source/destination check flag

### Use Cases

| Use Case | Description |
|---|---|
| **Management Network** | Separate ENI for management traffic |
| **Dual-Homed Instances** | Multiple subnets/security contexts |
| **Licensing** | MAC-based software licenses *(ENI retains MAC)* |
| **High Availability** | Move ENI between instances during failover |

### ENI Attachment

| Type | Behavior |
|---|---|
| **Primary ENI** | Created with instance; deleted with instance |
| **Secondary ENI** | Created independently; can be attached/detached dynamically |

---

## IPv6 in VPC

VPCs can be **dual-stack**, supporting both IPv4 and IPv6.

### IPv6 Characteristics

| Property | Details |
|---|---|
| **CIDR Block** | AWS assigns `/56` CIDR (256 × `/64` subnets) |
| **Addresses** | All IPv6 addresses are **public** |
| **Internet Access** | Requires Internet Gateway |
| **Outbound Only** | Egress-Only Internet Gateway *(IPv6 NAT equivalent)* |
| **NAT** | ❌ Not used — every IPv6 address is globally unique |

### Enabling IPv6

1. Associate IPv6 CIDR block with VPC
2. Assign `/64` IPv6 CIDR to subnets
3. Update route tables (`::/0 → IGW` or `EIGW`)
4. Auto-assign IPv6 addresses to instances
5. Update security groups/NACLs for IPv6

### Use Cases

- IoT applications (large address space)
- Applications requiring end-to-end addressing
- Modern applications designed for IPv6
- Compliance requirements

---

## Network Monitoring and Troubleshooting

### Comprehensive Monitoring Setup

- Create **CloudWatch dashboard** for network monitoring
- Create **CloudWatch alarms** for network issues
- Analyze **VPC Flow Logs** for security and performance insights

### Cost Optimization Strategies

**NAT Gateway Cost Reduction:**
- Analyze traffic patterns and optimize NAT Gateway usage

**Data Transfer Cost Optimization:**
- Use **VPC Endpoints** to avoid NAT Gateway charges for AWS services
- Use **Interface Endpoints** for services without Gateway Endpoints

---

## Tips & Best Practices

### CIDR Planning

#### Tip 1: Plan for Growth

```
❌ Bad:  /24 VPC (256 IPs) — runs out quickly, hard to expand
✅ Good: /16 VPC (65,536 IPs) — room for growth, future-proof
```

#### Tip 2: Use Non-Overlapping CIDR Blocks

Maintain a CIDR allocation spreadsheet:

```
10.0.0.0/16    Production VPC     (us-east-1)
10.1.0.0/16    Development VPC    (us-east-1)
10.2.0.0/16    Shared Services    (us-east-1)
10.10.0.0/16   Production VPC     (eu-west-1)
10.11.0.0/16   Development VPC    (eu-west-1)
172.16.0.0/12  Reserved           (on-premises)
192.168.0.0/16 Reserved           (future use)
```

#### Tip 3: Consistent Subnet Numbering

```
x.x.1.0/24    Public subnet AZ-A
x.x.2.0/24    Public subnet AZ-B
x.x.3.0/24    Public subnet AZ-C
x.x.11.0/24   App subnet AZ-A
x.x.12.0/24   App subnet AZ-B
x.x.13.0/24   App subnet AZ-C
x.x.21.0/24   DB subnet AZ-A
x.x.22.0/24   DB subnet AZ-B
x.x.23.0/24   DB subnet AZ-C
x.x.100.0/22  Reserved for expansion
```

### Network Segmentation

#### Tip 4: Implement Defense in Depth

```
Layer 1: Network ACLs       (Subnet level, stateless)
Layer 2: Security Groups    (Instance level, stateful)
Layer 3: Host-based firewall (OS level)
Layer 4: Application-level authorization
```

#### Tip 5: Use Security Group Chaining

```bash
# Web tier → App tier
aws ec2 authorize-security-group-ingress \
    --group-id $APP_SG --protocol tcp --port 8080 --source-group $WEB_SG

# App tier → Database tier
aws ec2 authorize-security-group-ingress \
    --group-id $DB_SG --protocol tcp --port 3306 --source-group $APP_SG
```

#### Tip 6: Minimize Public Subnets

Only use public subnets for resources that **absolutely need** public IPs:
- Load balancers
- NAT Gateways
- Bastion hosts
- VPN endpoints

### High Availability

#### Tip 7: Deploy NAT Gateways in Each AZ

```
NAT-GW-1A  in Public-Subnet-1A  →  Routes for AZ-A private subnets
NAT-GW-1B  in Public-Subnet-1B  →  Routes for AZ-B private subnets
NAT-GW-1C  in Public-Subnet-1C  →  Routes for AZ-C private subnets
```

> Prevents cross-AZ data transfer charges and eliminates single points of failure.

#### Tip 8: Use Elastic IPs Strategically

| ✅ Do use EIPs for | ❌ Don't use EIPs for |
|---|---|
| NAT Gateways (required) | Auto-scaled resources |
| Bastion hosts (consistent access) | Resources behind NAT |
| Resources needing IP whitelisting | Internal-only services |

#### Tip 9: Test Failover Scenarios

```bash
# Simulate NAT Gateway failure
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GW_1A
# Verify traffic fails over to other AZs
# Recreate NAT Gateway
```

### Performance Optimization

#### Tip 10: Use Enhanced Networking
- Enable **ENA (Elastic Network Adapter)** — up to 100 Gbps
- Requires supported instance types (C5, M5, R5, etc.)
- No additional cost

#### Tip 11: Leverage Placement Groups
For low-latency, high-throughput applications.

#### Tip 12: Optimize MTU Settings
Use jumbo frames (MTU 9001) within VPC.

### Monitoring and Troubleshooting

| Tip | Action |
|---|---|
| **Tip 13** | Enable VPC Flow Logs **from Day 1** — don't wait for an incident |
| **Tip 14** | Use **Reachability Analyzer** to test connectivity before deploying |
| **Tip 15** | Monitor **NAT Gateway Metrics** — set alarms for connection tracking errors |

### Security

#### Tip 16: Implement Least Privilege in Security Groups

```bash
# ❌ Bad
--cidr 0.0.0.0/0

# ✅ Good — specific CIDR
--cidr 203.0.113.0/24

# ✅ Better — reference security group
--source-group $TRUSTED_SG
```

#### Tip 17: Regular Security Group Audits
Find and remove unused or overly permissive security groups.

#### Tip 18: Use AWS Network Firewall
For stateful packet inspection on advanced use cases.

### Cost Optimization

#### Tip 19: Right-Size NAT Gateways
Analyze traffic patterns — consider consolidating multiple low-traffic NAT Gateways.

#### Tip 20: Use VPC Endpoints Aggressively
Create endpoints for all supported services to free up NAT Gateway capacity.

---

## Pitfalls & Remedies

### ⚠️ Pitfall 1: Inadequate CIDR Block Sizing

**Problem:** Choosing a CIDR block that's too small, leading to IP exhaustion.

**Why it happens:** Underestimating growth, trying to conserve IPs, not understanding subnet math.

**Impact:** Cannot add resources, forced migration to new VPC, lost agility.

**Example:**
```
VPC with /24 → Only 59 usable IPs per subnet
→ Auto Scaling can't add instances
→ Out of IPs after modest growth
```

**Remedy:**
1. Audit current IP usage
2. Add secondary CIDR block if needed
3. Design properly sized VPC (use `/16`)

**Prevention:**
- Always use `/16` for VPC CIDR unless you have specific constraints
- Plan for 3–5 years of growth
- Document CIDR allocation in a central registry
- Use a CIDR calculator before creating VPC

---

### ⚠️ Pitfall 2: Asymmetric Routing with Multiple NAT Gateways

**Problem:** Resources in one AZ using a NAT Gateway in another AZ, causing cross-AZ charges.

**Why it happens:** Using a single route table for all private subnets.

**Impact:** Unexpected cross-AZ data transfer charges (`$0.01/GB` each direction), reduced availability.

**Example:**
```
All private subnets → Private-RT → 0.0.0.0/0 → NAT-GW-1A (only in AZ-A)
❌ Instances in AZ-B and AZ-C cross AZ boundaries unnecessarily
```

**Remedy:**
1. Identify asymmetric routing
2. Implement AZ-specific route tables
3. Verify and validate routing configuration

**Prevention:**
- Create one NAT Gateway per AZ from the start
- Use separate route tables per AZ
- Monitor cross-AZ data transfer metrics

---

### ⚠️ Pitfall 3: Security Group Misconfigurations

**Problem:** Overly permissive rules, missing egress restrictions, or circular dependencies.

**Common Mistakes:**
```bash
# ❌ SSH open to the world
--protocol tcp --port 22 --cidr 0.0.0.0/0

# ❌ Database accessible from anywhere
--protocol tcp --port 3306 --cidr 0.0.0.0/0

# ❌ Allowing all traffic
--protocol -1 --cidr 0.0.0.0/0
```

**Remedy:**
1. Audit existing security groups for `0.0.0.0/0` rules
2. Replace with specific CIDRs or SG references
3. Implement automated monitoring
4. Set up EventBridge rules for SG change alerts

**Prevention:**
- Implement security group templates and IaC
- Enable automated scanning for dangerous rules
- Run regular audits (weekly/monthly)
- Use AWS Config rules for compliance

---

### ⚠️ Pitfall 4: Forgotten or Stale Routes

**Problem:** Route table entries pointing to deleted resources, causing traffic blackholing.

**Example:**
```
Route: 0.0.0.0/0 → nat-xxxxx (state: deleted)
Status: BLACKHOLE
Result: All outbound traffic silently dropped
```

**Remedy:**
1. Identify blackhole routes
2. Delete invalid routes and replace with valid targets
3. Implement route change notifications
4. Automate daily route table health checks

**Prevention:**
- Use Infrastructure as Code (routes in CloudFormation/Terraform)
- Run route validation before deleting network resources
- Monitor CloudTrail for route table changes

---

### ⚠️ Pitfall 5: VPC Peering Complexity at Scale

**Problem:** Full-mesh peering becomes unmanageable as VPCs grow.

**The Math:**
```
 5 VPCs  →   10 peering connections
10 VPCs  →   45 peering connections
20 VPCs  →  190 peering connections
```

**Impact:** Exponential complexity, difficult troubleshooting, route table entry limits reached.

**Remedy:**
1. Assess current peering complexity
2. Migrate to Transit Gateway
3. Clean up old peering connections

**Prevention:**
- Plan for **Transit Gateway from the start** if you expect >5 VPCs
- Document network topology clearly
- Implement network automation
- Conduct regular architecture reviews

---

## Summary

Amazon VPC is the **networking foundation of AWS**, providing isolated, software-defined networks with complete control over IP addressing, routing, and security.

### Key Takeaways

| Area | Guidance |
|---|---|
| **CIDR Planning** | Use `/16` VPCs with room for growth; maintain a central allocation registry |
| **High Availability** | Deploy across multiple AZs; one NAT Gateway per AZ with AZ-specific routing |
| **Security** | Layer security groups (stateful, instance-level) + NACLs (stateless, subnet-level) |
| **Routing** | Validate routes regularly; use Transit Gateway for multi-VPC environments |
| **VPC Endpoints** | Reduce NAT costs with Gateway Endpoints (S3/DynamoDB) and Interface Endpoints |
| **Monitoring** | Enable VPC Flow Logs from day one; build dashboards and automated alerts |
| **Scaling** | Use Transit Gateway (not peering) for >5–10 VPCs; plan for hybrid connectivity |

> Understanding VPC deeply enables you to build **secure, scalable, and cost-effective** network architectures that support both current needs and future growth.

---

## Hands-On Lab Exercise

**Objective:** Build a production-ready, highly available VPC with complete network isolation, multi-tier architecture, and hybrid connectivity simulation.

**Scenario:** Deploy a 3-tier application infrastructure with:
- Public web tier with Application Load Balancer
- Private application tier with Auto Scaling
- Private database tier with RDS Multi-AZ
- Bastion host for secure access
- VPC endpoints for AWS services
- VPN connectivity to simulated on-premises

### Exercise Steps

#### Step 1 — Design and Document Architecture
- [ ] Draw network diagram
- [ ] Plan CIDR allocation
- [ ] Document security group rules
- [ ] Define route table strategy

#### Step 2 — Deploy Core VPC Infrastructure
- [ ] Create VPC with `/16` CIDR
- [ ] Deploy 9 subnets across 3 AZs (public, app, database)
- [ ] Set up Internet Gateway and NAT Gateways
- [ ] Configure route tables

#### Step 3 — Implement Security Layers
- [ ] Create security groups for each tier
- [ ] Configure NACLs for additional protection
- [ ] Set up bastion host for SSH access
- [ ] Implement security group chaining

#### Step 4 — Deploy Application Components
- [ ] Launch Application Load Balancer in public subnets
- [ ] Create Auto Scaling Group in app subnets
- [ ] Deploy RDS Multi-AZ in database subnets
- [ ] Configure health checks

#### Step 5 — Optimize with VPC Endpoints
- [ ] Create S3 Gateway Endpoint
- [ ] Set up Systems Manager Interface Endpoints
- [ ] Test private connectivity

#### Step 6 — Enable Monitoring
- [ ] Enable VPC Flow Logs
- [ ] Create CloudWatch dashboard
- [ ] Set up alarms for anomalies

#### Step 7 — Test and Validate
- [ ] Verify connectivity between tiers
- [ ] Test AZ failover scenarios
- [ ] Validate security group restrictions
- [ ] Confirm monitoring is working

### Expected Outcomes

- ✅ Fully functional multi-tier VPC architecture
- ✅ Documented network design
- ✅ Working security controls
- ✅ Operational monitoring

---

*Notes taken from Amazon VPC study session — April 08, 2026*
