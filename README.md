## Designing and Building a Secure VPC for Production 3-Tier Architecture using Terraform

Automate VPC creation with Infrastructure as Code to design a Secure VPC for a Production Web Application. Build a
production-ready, secure and highly available VPC with complete network isolation, multi-tier architecture across 3
Availability Zones.

Imagine you're deploying a multi-tier web application (frontend, backend, and database) in AWS. The main goal is:

* **Secure** : Defense-in-depth network security
* **Scalable** : Built for growth and high availability
* **Cost-Optimized** : Reduce egress costs and maximize value
* **Enterprise-ready** : Governance, compliance and best practices
* **Automated** : Terraform, CI/CD and Infrastructure as Code

### Business Problem

***

Deploying an enterprise-grade multi-tier web application directly to the cloud without a strict architectural framework
exposes organizations to severe operational, financial, and compliance risks. Legacy or flat cloud network designs lack
complete network isolation between the web frontend, backend business logic, and database storage tiers. Without
automation and granular network controls, organizations face single points of failure, bloated egress data transfer
costs, fragmented compliance governance, and heightened exposure to security breaches.

### Core Challenges

***

- **Security & Defense-in-Depth**: Preventing public internet exposure to sensitive backend application logic and
  database layers requires a Zero Trust network posture. Designing multi-layered defenses across instance-level
  firewalls (Security Groups) and subnet-level network firewalls (PCI-compliant NACLs) without breaking required
  application traffic paths is complex.
- **High Availability & Multi-AZ Fault Tolerance**: Ensuring high availability across 3 Availability Zones requires
  managing complex CIDR subnet allocations, dual-path routing tables, and redundant outbound gateways (NAT Gateways) to
  eliminate single points of failure.
- **Cost & Route Optimization**: Uncontrolled outbound traffic over public internet routes increases cloud egress
  expenses. Traffic bound for internal services (e.g., S3 and DynamoDB) must be routed securely and cost-effectively
  through private endpoints rather than crossing the public internet.
- **Infrastructure Management & Governance**: Manual, console-driven infrastructure provisioning creates configuration
  drift, lacks auditability, and leads to security misconfigurations. Integrating automated IaC (Terraform) alongside
  CI/CD deployment pipelines and automated static security checks (e.g., Checkov) is essential for enterprise compliance
  and repeatability.
- **Observability & Auditing**: Gaining visibility into VPC traffic paths for troubleshooting, threat detection, and
  compliance auditing requires continuous network flow logging without degrading network performance.

### What is an Amazon VPC?

***

With Amazon Virtual Private Cloud (Amazon VPC), you can create a VPC in AWS, which is a logically isolated network
dedicated to your AWS account. It allows you to define a virtual network that mimics a traditional on-premises network
but with the scalability, flexibility, and security of AWS. When you create a VPC, you define an IP address range (CIDR
block), subnets, route tables, and other networking components that determine how AWS resources—for example, Amazon
Elastic Compute Cloud (Amazon EC2) instances—can communicate with each other and the internet.

VPCs are crucial for controlling how network traffic flows into and out of AWS resources. A VPC provides the following
core features:

- **Complete network isolation** – You can launch your resources like Amazon RDS for Db2, Amazon EC2, and more inside
  your VPC and fully control the incoming and outgoing traffic by configuring security groups and network access control
  lists (ACLs).
- **Security** – Security is a fundamental aspect of VPC. AWS provides security groups and network ACLs that allow you
  to control traffic at the instance and subnet level, respectively.

A VPC includes the following components:

- **Subnets** – You can divide the VPC into subnets, which represent isolated network segments within the VPC. Subnets
  can be public (accessible from the internet) or private (internal only).
- **Route tables** – You can set up route tables to control the routing of traffic within the VPC, and between other
  VPCs and the internet.
- **Gateways and interface endpoints** – You can configure internet gateways, NAT gateways, and VPC endpoints to manage
  how traffic flows between your VPC and external networks—for example, the internet or AWS services like Amazon Simple
  Storage Service (Amazon S3).

### Architecture Overview

***

This Terraform configuration deploys a highly available, secure AWS VPC infrastructure across multiple availability
zones with the following components:

**Core Components**

* **VPC**: Production-grade Virtual Private Cloud with DNS support
* **Subnets**: Both public and private subnets across multiple availability zones
* **NAT Gateways**: Internet connectivity for private subnets
* **Internet Gateway**: Direct internet access for public subnets
* **Route Tables**: Separate routing for public and private traffic
* **Security Groups**: Default security group with permissive rules
* **VPC Endpoints**: Gateway endpoints for S3 and DynamoDB services
* **Network ACLs**: Additional network-level security
* **Flow Logs**: VPC traffic monitoring and logging

### Architecture Diagram

***

**Architecture Overview**

**VPC: 10.0.0.0/16**

* Public Tier (Web):

```
10.0.1.0/24 (us-east-1a)
10.0.2.0/24 (us-east-1b)
10.0.3.0/24 (us-east-1c)
```

* Application Tier:

```
10.0.11.0/24 (us-east-1a)
10.0.12.0/24 (us-east-1b)
10.0.13.0/24 (us-east-1c)
```

* Database Tier:

```
10.0.21.0/24 (us-east-1a)
10.0.22.0/24 (us-east-1b)
10.0.23.0/24 (us-east-1c)
```

![secure-vpc-for-three-tier-web-app.png](secure-vpc-for-three-tier-web-app.png)

### Architecture Details

***

**Network Design**

* CIDR: 10.0.0.0/16

**Public Subnets**: Host resources that need direct internet access (load balancers, bastion hosts)

* Public Subnets: 10.0.1.0/24 (AZ-a), 10.0.2.0/24 (AZ-b), 10.0.3.0/24 (AZ-c)

**Private Subnets**: Host internal resources (application servers, databases)

* Private Subnets (App): 10.0.11.0/24 (AZ-a), 10.0.12.0/24 (AZ-b), 10.0.13.0/24 (AZ-c)
* Private Subnets (Data): 10.0.21.0/24 (AZ-a), 10.0.22.0/24 (AZ-b), 10.0.23.0/24 (AZ-c)
* NAT Gateways: 3 (one per AZ for high availability)
* Multi-AZ Deployment: Resources span multiple availability zones for high availability

**Security Features**

* Network ACLs: Additional layer of security at the subnet level
* Security Groups: Instance-level firewall rules
* Flow Logs: Monitor and log VPC traffic for security analysis
* VPC Endpoints: Secure access to AWS services without internet routing

**Routing Configuration**

* Public Route Table: Routes internet traffic through Internet Gateway
* Private Route Tables: Routes internet traffic through NAT Gateways (one per AZ)

### Traffic Flow

***

![vpc_traffic_flow.svg](vpc_traffic_flow.svg)

Here's the traffic flow derived from the architecture diagram. The path goes:

1. **Inbound** — Users hit the Internet Gateway, which forwards traffic to the Application Load Balancer sitting in the
   public subnets across all three AZs.
2. **Application tier** — The ALB distributes requests down to the private application subnets (10.0.11–13.0/24). These
   servers handle your business logic.
3. **Data tier** — The app servers query the databases/caches in the private data subnets (10.0.21–23.0/24). No direct
   internet access here.
4. **Outbound (dashed lines)** — The private app tier routes outbound traffic (e.g. for package downloads or API calls)
   back up through the NAT Gateways in the public subnets, which then exit via the IGW.
5. **CI/CD** — GitHub pushes trigger GitHub Actions, which deploys directly to your AWS infrastructure.

### Implementation

***
**Step 1: Project Structure**

```
secure-vpc-for-three-tier-web-app/
├── AWS services study note         # AWS services study note
├── Documentation                   # Documentation of this project
└── modules/
    └── bootstrap/                  # Backend for Terraform state file
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
    └── iam/                        # IAM for Role and permission
        ├── ga-oidc.tf              # IAM role Terraform execution ARN for GitHub Actions CI/CD using OIDC (OpenID Connect)
        ├── outputs.tf
        └── variables.tf
    └── vpc/                        # VPC for networking
        ├── main.tf
        ├── outputs.tf
        └── variables.tf
   ├── Screenshot verification      # Screenshot verification after success deployment
   ├── .gitignore                   # gitignore
   ├── backend.tf                   # Backend configuration for Terraform state file
   ├── data.tf                      # Data sources
   ├── locals.tf                    # locals for common_tags
   ├── main.tf                      # Main infrastructure resources
   ├── outputs.tf                   # Output values
   ├── dev-terraform.tfvars         # The terraform.tfvars file for dev
   ├── staging-terraform.tfvars     # The terraform.tfvars file for staging
   ├── prod-terraform.tfvars        # The terraform.tfvars file for prod
   ├── providers.tf                 # Terraform and AWS provider configuration
   ├── variables.tf                 # Input variables and defaults
   ├── .github/workflows/
      ├── website-deployment.yml    # Static Website deployment workflows
      ├── terraform-checkov.yml     # Checkov workflows
```

**Step 2: Modules**

- **bootstrap** — Backend for Terraform state file
- **iam** — IAM for Role and permission
- **vpc**
    - Create VPC + DNS flags ```aws_vpc.main```
    - Internet Gateway + attach ```aws_internet_gateway.main```
    - 9 subnets (public/app/db × 3 AZs) ```aws_subnet.public/app/db``` (count loops)
    - 3 EIPs + NAT Gateways ```aws_eip.nat```, ```aws_nat_gateway.main```
    - 1 public RT + 3 private RTs ```aws_route_table.public/private``` + associations
    - 4 Security Groups + ingress rules ```aws_security_group.web/app/db/bastion``` + ```aws_security_group_rule```
    - Public NACL + inbound/outbound rules ```aws_network_acl.public```
    - S3 + DynamoDB Gateway Endpoints ```aws_vpc_endpoint.s3/dynamodb```

**Step 3: Outputs**<br>
After successful deployment, the following outputs will be available:

- ```vpc_id``` — ID of the created VPC
- ```public_subnets``` — List of public subnet IDs
- ```private_subnets``` — List of private subnet IDs
- ```nat_gateways``` — List of NAT Gateway IDs
- ```internet_gateway``` — Internet Gateway ID
- ```vpc_cidr``` — CIDR block of the VPC

![0-Outputs 1.png](Screenshot%20verification/0-Outputs%201.png)

![0-Outputs 2.png](Screenshot%20verification/0-Outputs%202.png)

**Step 4: Deployment Workflow**

- ```checkov.yml``` — Automated security scanning framework using Checkov to detect Terraform misconfigurations at both
  repository and pull request (PR) levels.
- ```deploy.yml``` — Terraform workflow to provision infrastructure and deploy a production-grade secure Virtual Private
  Cloud (VPC) on AWS — provisioning VPC, Subnets, NAT Gateways, Internet Gateway, Route Tables, Security Groups, VPC
  Endpoints, Network ACLs and Flow Logs.

### Quick Start

***

- **Step 1 — Fork and clone**
    - $ git clone https://github.com/darvin-rakotomalala/secure-vpc-for-three-tier-web-app
    - $ cd secure-vpc-for-three-tier-web-app

- **Step 2 — Configure Terraform**<br>
  Edit ```secure-vpc-for-three-tier-web-app/dev-terraform.tfvars``` to match your target region and preferences. No
  secrets go here — just region, domain name, and default tags.

- **Step 3 — Deploy infrastructure**

  ```
  $ cd secure-vpc-for-three-tier-web-app
  $ terraform init
  $ terraform fmt -recursive
  $ terraform validate
  $ terraform plan -var-file="dev-terraform.tfvars" -no-color -out=TFplan.JSON
  $ terraform apply -var-file="dev-terraform.tfvars" -auto-approve
  ```

  **Migration to remote backend**

    - Add or activate backend configuration : ```backend.tf```
    - Reinitialize to migrate state: ```terraform init -migrate-state```

### Verification

***
You can check the full documentation in ```Documentation``` directory and all screenshot in
```Screenshot verification```.

- **VPC**

![1-VPC.png](Screenshot%20verification/1-VPC.png)

- **Internet Gateway**

![2-Internet Gateway.png](Screenshot%20verification/2-Internet%20Gateway.png)

- **Subnets**

![3-Subnets.png](Screenshot%20verification/3-Subnets.png)

- **NAT Gateways**

![5-NAT Gateways.png](Screenshot%20verification/5-NAT%20Gateways.png)

- **Route Tables**

![6-Route Tables.png](Screenshot%20verification/6-Route%20Tables.png)

- **Security Groups**

![10-Security groups.png](Screenshot%20verification/10-Security%20groups.png)

- **Network ACLs (Additional Layer)**

![7-NACLs.png](Screenshot%20verification/7-NACLs.png)

- **VPC Endpoints**

![8-VPC Endpoints.png](Screenshot%20verification/8-VPC%20Endpoints.png)

- **VPC Flow Logs**

![9-Flow logs details.png](Screenshot%20verification/9-Flow%20logs%20details.png)

### Cleanup

***
To destroy all resources, run ```terraform destroy -var-file="dev-terraform.tfvars" -auto-approve```

### License

***
This project is for learning and demonstration purposes. You can adapt or extend it for your own use.
