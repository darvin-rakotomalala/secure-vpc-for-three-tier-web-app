## Designing and Building a Secure VPC for Production 3-Tier Architecture

**Objective**: Create a highly available, secure VPC with public, application, and database tiers across 3 Availability
Zones.

### Architecture Overview

**VPC**: 10.0.0.0/16

**Public Tier (Web):**

- 10.0.1.0/24 (us-east-1a)
- 10.0.2.0/24 (us-east-1b)
- 10.0.3.0/24 (us-east-1c)

**Application Tier:**

- 10.0.11.0/24 (us-east-1a)
- 10.0.12.0/24 (us-east-1b)
- 10.0.13.0/24 (us-east-1c)

**Database Tier:**

- 10.0.21.0/24 (us-east-1a)
- 10.0.22.0/24 (us-east-1b)
- 10.0.23.0/24 (us-east-1c)

### Architecture diagram

![secure-vpc-for-three-tier-web-app.jpg](../secure-vpc-for-three-tier-web-app.jpg)

### Steps implementation

**Step 1: Create VPC**

- Create VPC
- Enable DNS hostnames
- Enable DNS support (enabled by default, but verify)

**Step 2: Create Internet Gateway**

- Create IGW
- Attach IGW to VPC

**Step 3: Create Subnets**

- Public Subnets per AZ for ALB and Bastion
- Enable auto-assign public IP for public subnets
- Application Private Subnets per AZ
- Database Private Subnets per AZ

**Step 4: Create NAT Gateways**

- Allocate Elastic IPs for NAT Gateways
- Create Elastic IP per AZ
- Create NAT Gateways (one per AZ for high availability)

**Step 5: Create Route Tables**

- Public Route Table
- Add route to Internet Gateway
- Associate public subnets with public route table
- Private Route Tables (one per NAT Gateway)
- Associate App Tier subnets
- Associate Data Tier subnets

**Step 6: Create Security Groups**

- Network:
    - ALB-SG Web Tier Security Group (Public-facing) : Allow 80/443 from internet
    - BASTION-SG Bastion Host Security Group (for SSH access): Allow SSH 22 from anywhere
    - APP-SG Security Group (ALB to App tier): Inbound from ALB-SG
    - DB-SG Security Group (App tier to Data tier): Allow 3306/5432 from APP-SG App tier
- ALB Security Group (Public-facing)
    - Allow HTTP from anywhere
    - Allow HTTPS from anywhere
- Application Tier Security Group
    - Allow traffic from web tier on port 8080/443
- Database Tier Security Group
    - Allow PostgreSQL from application tier
- Bastion Host Security Group (for SSH access) in Public Subnets
    - Allow SSH from your IP/CIDR (replace with your IP)
    - Allow SSH from bastion to APP and DB tiers

**Step 7: Create Network ACLs (Additional Layer)**

- Public subnets NACL: Allow 80, 443 inbound, Ephemeral ports (for return traffic) outbound
- Associate with public subnets
- Private subnets NACL: Deny all inbound from internet, allow VPC CIDR
- Data subnets NACL: Deny all except from application subnet CIDR

**Step 8: Create VPC Endpoints**

- S3 Gateway Endpoint (free, for private S3 access)
- DynamoDB Gateway Endpoint

**Step 9: Create VPC Flow Logs**

- VPC Flow Logs to CloudWatch
