# AWS VPC CHECKLIST

> *Production-Level VPC Design: Hard-Won Lessons from the Trenches of AWS Architecture*

Designing a VPC using AWS Well-Architected Framework principles means VPC design isn't just about networking — it's about building the foundation that either enables or constrains every other architectural decision you'll make.

Production-level VPC design requires thinking like both a **network engineer** and a **business strategist**.

Every AWS application sits inside a VPC. If you don't understand networking fundamentals, everything else falls apart.

---

## 🧱 The 7 Essential Components

| Component | Description |
|---|---|
| ✅ **Route Tables** | Traffic maps that decide where packets go |
| ✅ **Security Groups** | Instance-level firewalls. Allow-only and stateful |
| ✅ **Internet Gateway (IGW)** | The door to the internet. One per VPC |
| ✅ **VPC** | Your isolated network container, defined by a CIDR block |
| ✅ **NACLs** | Subnet-level firewalls. Stateless, with allow and deny rules |
| ✅ **Subnets** | Public subnets reach the internet. Private subnets stay hidden |
| ✅ **NAT Gateway** | Lets private resources reach out without exposing them to inbound traffic |

> **Security is layered.** NACLs filter at the subnet boundary, Security Groups at the resource level. Both must allow traffic for it to pass.

---

## 📚 Everything You Need to Know About VPCs

- What Is a VPC, Really?
- VPC (Virtual Private Cloud)
- Subnets
- Internet Gateway (IGW)
- Route Tables
- NAT Gateway
- Security Groups
- Network ACLs (NACLs)

---

## 🏛️ Foundation Principles: The Well-Architected Approach

The AWS Well-Architected Framework provides **five pillars** that should guide every VPC design decision:

1. Operational Excellence
2. Security
3. Reliability
4. Performance Efficiency
5. Cost Optimization

---

## ⚙️ Operational Excellence

### The Subnet Strategy That Actually Works

Always start with a subnet strategy that follows the **"3x3x3 rule"**:

- **3 availability zones** minimum for production workloads
- **3 subnet types** per AZ (public, private, database)
- **3 sizes larger** than your current needs

### Tagging Strategy for Operational Clarity

Without proper tags, what should have been a 10-minute query can turn into a two-day manual inventory.

**Standard tagging approach:**

| Tag Key | Example Values |
|---|---|
| `Environment` | production, staging, development |
| `Function` | web, app, database, management |
| `Owner` | team or service responsible |
| `Project` | business initiative or application name |
| `CostCenter` | for accurate cost allocation |

---

## 🔒 Security: Defense in Depth Through Network Design

### Network ACLs vs. Security Groups

| | Network ACLs | Security Groups |
|---|---|---|
| **Scope** | Subnet-level | Instance-level |
| **State** | Stateless | Stateful |
| **Rules** | Allow + Deny | Allow only |
| **Use case** | Broad traffic patterns | Specific application requirements |

Network ACLs serve as the "traffic cop" at the subnet boundary — for example, ensuring that **database subnets can only receive traffic from application subnets on specific ports**.

### VPC Flow Logs: Your Security Crystal Ball

- ✅ Enable VPC Flow Logs — but configure them **strategically**
- ✅ Send to **CloudWatch Logs** for real-time analysis
- ✅ Send to **S3** for long-term storage and compliance
- ✅ Cost is usually **under $50/month** for a production VPC — the security value is immeasurable

---

## 🔁 Reliability: Building for Failure

### Multi-AZ by Design, Not by Accident

Ensuring true multi-AZ resilience requires:

1. Independent subnet groups in each AZ with full functionality
2. **Dedicated NAT Gateways** in each public subnet (not shared)
3. Cross-AZ redundancy for critical services like databases
4. Route table isolation to prevent single points of failure

> ⚠️ **The NAT Gateway design is critical.** Sharing a single NAT Gateway across multiple AZs creates a hidden single point of failure. The additional cost (~$45/month per NAT Gateway) is worth the availability improvement.

### Connection Limits and Scaling Considerations

| Resource | Limit |
|---|---|
| VPC endpoints | 255 per VPC |
| NAT Gateway connections | 55,000 simultaneous |
| Security groups per instance | 5 (up to 60 total rules) |
| Network interfaces per instance | Varies by instance type |

---

## ⚡ Performance Efficiency: Every Packet Matters

### Placement Groups and Enhanced Networking

For compute-intensive workloads:

- ✅ **Cluster placement groups** for tightly coupled workloads
- ✅ **SR-IOV enabled instances** for maximum network performance
- ✅ **Dedicated tenancy** when consistent performance is critical
- ✅ Launch instances with enhanced networking

### Bandwidth and Burst Credits

| Instance Type | Network Performance |
|---|---|
| T3/T4g | Burstable (monitor credits in CloudWatch) |
| M5/M6i | Up to 25 Gbps |
| C5n | Up to 100 Gbps |

---

## 💰 Cost Optimization: Every Dollar Counts

### Data Transfer Costs: The Hidden Budget Killer

| Transfer Type | Cost |
|---|---|
| Same AZ | **Free** |
| Cross-AZ within region | $0.01 per GB |
| Cross-region | $0.02–$0.09 per GB |
| Internet egress (first 10TB) | $0.09 per GB |

**Cost optimization checklist:**

- ✅ VPC endpoints for AWS services (avoid NAT Gateway costs)
- ✅ Regional data residency to minimize cross-region transfer
- ✅ CloudFront for static content distribution
- ✅ Direct Connect for predictable, high-volume data transfer

### VPC Endpoints vs. NAT Gateway Economics

| | VPC Endpoint | NAT Gateway |
|---|---|---|
| Hourly charge | None | ~$45/month |
| Data processing | $0.01/GB | $0.045/GB |

> For high-volume S3 or DynamoDB access, **VPC endpoints almost always win**.

---

## 🏗️ Real-World Implementation: A Complete Example

**Target SLA:** 99.99% availability, sub-100ms response times, scalable to 10x current traffic.

### Architecture Properties

```yaml
VPC:
  CidrBlock: 10.0.0.0/16
  EnableDnsHostnames: true
  EnableDnsSupport: true
  Tags:
    Name: Hub-VPC
    Environment: production
    Function: shared-services
```

### Monitoring and Troubleshooting

Key metrics to track for every production VPC:

| Metric | Target |
|---|---|
| Network packet loss | < 0.01% |
| Latency between AZs | < 2ms |
| NAT Gateway connection count | Alert at 80% of limit |
| VPC Flow Logs anomalies | Monitor for unexpected traffic patterns |
| DNS resolution times | Critical for microservices architectures |

---

## 📖 Lessons Learned and Future Considerations

- **Start Simple, Evolve Strategically** — build only what you need, with room to grow
- **Automation Is Non-Negotiable** — manual VPC management doesn't scale
- **Security by Design, Not by Addition** — security cannot be retrofitted; every design decision must consider security implications from the start
- **Performance Baseline Everything** — you cannot optimize what you cannot measure; implement comprehensive monitoring from day one

---

## 🛡️ Securing VPC, Subnets, and Network Architecture for Production-Grade Applications

### Best Practices Overview

- ✅ **Secure subnet segmentation** (public vs. private)
- ✅ **IAM roles & least privilege access** to prevent breaches
- ✅ **Encryption & data protection** for sensitive workloads
- ✅ **Logging, monitoring, and network traffic analysis**
- ✅ **Security Groups vs. NACLs** — when and how to use them

---

## 1. VPC Design and Security Best Practices

### 1.1 Choose an Optimal CIDR Block

- Choose a **non-overlapping private CIDR block** (e.g., `10.0.0.0/16` or `192.168.0.0/16`) to avoid IP conflicts with on-premises networks
- Plan subnet sizes carefully based on anticipated workload scalability

### 1.2 Enable VPC Flow Logs

- Enable **VPC Flow Logs** to capture network traffic logs
- Store logs in **AWS CloudWatch Logs** or **S3** with proper lifecycle management
- Apply **least privilege IAM policies** to restrict log access

---

## 2. Subnet Security Best Practices

### 2.1 Use a Multi-AZ Deployment

- Deploy **public and private subnets** across multiple **Availability Zones (AZs)** for high availability
- Ensure critical services (DBs, application servers) run in **private subnets**

### 2.2 Private vs. Public Subnets

| Subnet Type | Use For | Rules |
|---|---|---|
| **Public Subnets** | Load balancers, bastion hosts | Allow HTTP/HTTPS (80/443) only; use ALB/NLB |
| **Private Subnets** | App servers, databases | No direct internet access; use NAT Gateway for outbound |

### 2.3 Secure NAT Gateway Traffic

- Attach a **security group to the NAT Gateway** to restrict outbound traffic
- Use **VPC endpoints** instead of NAT Gateway for AWS service access to reduce costs

---

## 3. Security Groups and Network ACLs

### 3.1 Security Groups (Stateful Firewall Rules)

- Follow the **principle of least privilege** — only allow necessary inbound/outbound traffic
- Use **separate security groups** for different components:

| Security Group | Allowed Traffic |
|---|---|
| **Web SG** | HTTP/HTTPS (80, 443) from anywhere |
| **App SG** | Traffic only from Web SG |
| **DB SG** | MySQL/PostgreSQL (3306, 5432) from App SG only |
| **Bastion SG** | SSH (22) from trusted IPs only |

### 3.2 Network ACLs (NACLs) — Stateless Firewall Rules

- Implement **deny-all default rules** and explicitly allow necessary ports
- Ensure **egress traffic is restricted** to prevent data exfiltration

**Example NACL Rules:**

```
✅ Allow inbound HTTP/HTTPS from anywhere
❌ Deny all inbound traffic except required ports
✅ Allow outbound traffic only to trusted endpoints
```

---

## 4. Identity and Access Management (IAM) Security Best Practices

### 4.1 Implement Least Privilege IAM Policies

- Use **IAM roles** instead of long-term IAM user credentials
- Define **separate roles** for EC2, Lambda, RDS, S3 with minimal permissions

### 4.2 Secure SSH Access with IAM Roles and SSM

- **Disable direct SSH access** — use AWS Systems Manager (SSM) Session Manager instead
- Attach necessary IAM permissions for SSM to allow secure remote access

---

## 5. Encryption and Data Security

### 5.1 Enable Encryption at Rest

- **RDS, EBS, S3, SQS, Secrets Manager, Parameter Store** must use **KMS encryption**
- Enable default encryption for new EBS volumes

### 5.2 Enable Encryption in Transit

- Enforce **TLS 1.2** for ALB, CloudFront, and RDS connections
- Use **ACM (AWS Certificate Manager)** to manage SSL certificates

---

## 6. Monitoring, Auditing, and Logging

### 6.1 Implement CloudTrail for Security Audits

- Enable **AWS CloudTrail** to log all API activities
- Store logs securely in an **S3 bucket** with encryption and lifecycle policies

### 6.2 Implement AWS Config for Compliance Monitoring

- Use **AWS Config** to detect non-compliant security configurations
- Set up **remediation actions** to fix misconfigurations automatically

---

## ✅ Summary

This checklist provides a comprehensive approach to securing AWS VPC, subnets, security groups, IAM, encryption, and monitoring for a highly available, production-grade application.

By implementing these best practices, you can design a **secure and scalable AWS architecture** with:

- Strong access control
- Least privilege principles
- Encrypted data at rest and in transit
- Real-time monitoring and alerting
