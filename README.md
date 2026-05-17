# AWS Enterprise Security Lab

## Overview
This project deploys a production-grade, secure AWS environment using Terraform 
Infrastructure as Code (IaC). Built to simulate real-world cloud engineering 
responsibilities including network architecture, identity management, compute 
deployment, audit logging, AI-powered security monitoring, container orchestration, 
and CI/CD automation. Every resource is version controlled, reproducible, and 
aligned with zero trust principles and NIST 800-53 compliance standards.

## Architecture Overview

### Phase 1: Network Foundation

**Explain like I'm 5:**
Imagine you're building a new office building. Before anyone can work there you need 
to design the floor plan. You decide which rooms face the street and which ones are 
in the back away from the public. You put a front door for visitors and make sure the 
back rooms have no windows facing the street. This phase builds that floor plan for 
your cloud environment. The VPC is the building, the public subnet is the front 
office, the private subnet is the back room where sensitive work happens, and the 
internet gateway is the front door.

**What was built:**
Deployed a multi-tier VPC architecture with public and private subnets, an internet 
gateway, route tables enforcing network isolation, and security groups implementing 
microsegmentation. The private subnet has no internet route by design, ensuring 
sensitive workloads are fully isolated at the routing layer.

- VPC with 10.0.0.0/16 address space
- Public subnet (10.0.1.0/24) with internet gateway routing
- Private subnet (10.0.2.0/24) with no internet path
- Deny-by-default security groups with microsegmentation between tiers

---

### Phase 2: Identity and Compute

**Explain like I'm 5:**
Now that the building exists you need to put a computer in the back room and give it 
a badge so it knows what it is allowed to do. The badge says "you are allowed to 
write to the log book and nothing else." You also set up a special intercom system so 
you can talk to the computer securely without leaving any doors or windows open. When 
the computer turns on for the first time it reads a checklist and automatically 
installs everything it needs without anyone having to go in and do it manually.

**What was built:**
Deployed an EC2 instance into the private subnet with a least privilege IAM role 
attached via instance profile. The instance uses AWS Systems Manager for secure 
remote access with no SSH ports open. A Bash user data script automatically installs 
and configures the CloudWatch agent on first boot with zero manual intervention.

- IAM role with only 5 CloudWatch permissions - nothing more
- SSM managed instance for keyless, portless remote access
- EC2 instance with automated CloudWatch agent configuration via user data
- No hardcoded credentials anywhere in the codebase

---

### Phase 3: Storage and Audit Logging

**Explain like I'm 5:**
Imagine every single thing that happens in your building gets written down in a 
special notebook. Someone opened a door - written down. Someone changed a security 
rule - written down. Someone logged in - written down. The notebook is stored in a 
locked safe that nobody can tamper with. If someone tries to tear a page out you can 
tell because each page has a special seal. This phase builds that notebook and safe 
for your cloud environment.

**What was built:**
Built a complete audit logging pipeline capturing every API call made in the AWS 
account. CloudTrail writes to an encrypted, versioned S3 bucket with log file 
validation enabled so tampering can be detected. Logs also stream to CloudWatch in 
real time for immediate visibility.

- S3 bucket with AES-256 encryption, versioning, and public access blocked
- CloudTrail multi-region trail capturing all API calls globally
- Log file validation hash on every log file for tamper detection
- Real time streaming to CloudWatch for immediate alert capability

---

### Phase 4: Security Monitoring and AI Anomaly Detection

**Explain like I'm 5:**
Now that everything is being written in the notebook you need someone to actually 
read it and raise the alarm when something suspicious happens. You hire four security 
guards. Two of them are traditional guards who sound the alarm the moment they see 
even one bad thing happen. The other two are smarter - they watch normal activity 
for a while, learn what normal looks like, and then raise the alarm when something 
feels off even if it looks almost normal. Together they cover everything. When this 
was built one of the alarms went off immediately because the master key was being 
used to set things up - exactly as it should work.

**What was built:**
Built a security monitoring layer on top of CloudTrail using CloudWatch metric filters 
and alarms. Monitors four critical security events with a mix of fixed threshold and 
machine learning anomaly detection alarms. A single pane of glass dashboard provides 
real time visibility across all security metrics.

During deployment the root account usage alarm immediately fired - demonstrating the 
monitoring system working exactly as designed in a real scenario.

- Failed console login detection with ML anomaly detection baseline
- Unauthorized API call detection with zero tolerance threshold
- Root account usage alarm - any root login triggers immediate alert
- IAM policy change detection with ML anomaly detection baseline
- CloudWatch dashboard with real time security posture visibility

---

### Phase 5: Container Deployment

**Explain like I'm 5:**
Imagine you built a really useful robot. You want to run copies of that robot in 
different places without rebuilding it from scratch every time. So you put the robot 
in a box with everything it needs to work. That box can be shipped anywhere and the 
robot works the same way every time. This phase creates a private storage room for 
your robot boxes, automatically checks each box for viruses before storing it, and 
then tells AWS to keep exactly one robot running at all times and automatically 
replace it if it breaks.

**What was built:**
Deployed a containerized workload on AWS ECS Fargate with a private ECR registry. 
The registry automatically scans every pushed image for vulnerabilities. The ECS 
service maintains desired container count automatically, replacing unhealthy 
containers using built in health checks. Container Insights provides cluster level 
performance monitoring.

- ECR private registry with automatic vulnerability scanning on push
- ECR lifecycle policy keeping only the last 10 images
- ECS Fargate cluster with Container Insights enabled
- Nginx container with health checks and automatic replacement
- Container logs streaming to CloudWatch in real time

---

### Phase 6: CI/CD Pipeline

**Explain like I'm 5:**
Every time you change anything in your building's blueprint and submit it for 
approval, an automatic inspector immediately shows up and checks the whole blueprint 
before anyone can approve it. The inspector checks that everything is written neatly, 
that all the rooms are connected properly, and that no security rules were accidentally 
broken. If something is wrong the inspector flags it immediately so you can fix it 
before it becomes a real problem. This phase builds that automatic inspector for your 
infrastructure code.

**What was built:**
Built a GitHub Actions pipeline that automatically validates every code change on 
push. The pipeline enforces consistent formatting, validates HCL syntax, and runs 
tfsec security scanning against AWS best practices. Pull requests also generate a 
terraform plan showing exactly what infrastructure changes would be deployed before 
merging.

- Automatic trigger on every push to main and every pull request
- Terraform formatting enforcement
- HCL syntax validation
- tfsec security scanning against AWS security best practices
- Terraform plan generation on pull requests for change visibility

---

## Security Design Decisions
- **Zero trust networking:** All inbound traffic denied by default, explicit allow only
- **Microsegmentation:** Private tier only accepts traffic from public security group
- **Least privilege IAM:** Every role has only the minimum permissions required
- **No SSH ports:** Remote access via AWS Systems Manager only
- **No hardcoded credentials:** IAM roles, instance profiles, and GitHub Secrets only
- **Encryption at rest:** S3 bucket encrypted with AES-256
- **Audit logging:** Every API call captured with tamper-evident log file validation
- **Immutable audit trail:** S3 versioning prevents log deletion or modification
- **Automated security scanning:** tfsec runs on every code push

## Compliance Alignment
- NIST 800-53 SC-7 - Boundary Protection
- NIST 800-53 AC-3 - Access Enforcement
- NIST 800-53 AC-6 - Least Privilege
- NIST 800-53 AU-2 - Audit Events
- NIST 800-53 AU-9 - Protection of Audit Information
- NIST 800-53 SI-3 - Malicious Code Protection
- Zero Trust Architecture principles throughout

## Technologies Used
- Terraform v1.15.2
- Amazon Web Services - VPC, EC2, IAM, S3, CloudTrail, CloudWatch, ECS, ECR
- AWS CLI
- HCL (HashiCorp Configuration Language)
- Docker / Nginx
- GitHub Actions
- tfsec
- Bash scripting

## Repository Structure
<<<<<<< HEAD
```aws-enterprise-security-lab/
=======

```
aws-enterprise-security-lab/
>>>>>>> 1985235de44a74531c49d100cb7b125eb4d05a3c
├── main.tf              # VPC, subnets, internet gateway, route tables, security groups
├── variables.tf         # Input variables for region, project name, CIDRs
├── outputs.tf           # Output values displayed after deployment
├── iam.tf               # IAM roles, policies, and instance profiles
├── ec2.tf               # EC2 instance and AMI data source
├── cloudtrail.tf        # S3 bucket, CloudTrail, and CloudWatch log group
├── monitoring.tf        # CloudWatch metric filters, alarms, and dashboard
├── ecs.tf               # ECR, ECS cluster, task definition, and service
├── .github/
│   └── workflows/
│       └── terraform.yml  # GitHub Actions CI/CD pipeline
└── .gitignore           # Excludes state files and sensitive data
```
## Prerequisites
- Terraform installed
- AWS CLI installed and configured via aws configure
- Active AWS account

## How to Deploy

Clone the repository:

    git clone https://github.com/Nkwele1/aws-enterprise-security-lab.git
    cd aws-enterprise-security-lab

Initialize Terraform:

    terraform init

Preview the deployment:

    terraform plan

Deploy all infrastructure:

    terraform apply

Tear down when done:

    terraform destroy

## Key Findings During Build
- Root account usage alarm fired immediately upon deployment confirming 
  the monitoring pipeline was working correctly in real time
- tfsec CI/CD scan identified security improvement opportunities including 
  EBS volume encryption and S3 access logging which represent real world 
  hardening opportunities in production environments
- CloudTrail began streaming live API call data to CloudWatch within minutes 
  of deployment demonstrating end to end audit logging functionality

## Skills Demonstrated
- Enterprise AWS network architecture and segmentation
- IAM least privilege design and identity management
- Infrastructure as Code with Terraform across 6 service domains:
    - (Networking - VPC, subnets, security groups, route tables
    - Identity and Access Management - IAM roles, policies, instance profiles
    - Compute - EC2 instances, AMI, user data scripts
    - Storage and Compliance - S3, CloudTrail, audit logging
    - Monitoring and Security - CloudWatch, metric filters, anomaly detection alarms
    - Container Orchestration - ECS, ECR, Fargate, Docker)
- EC2 deployment automation with user data scripting
- S3 security hardening and compliance configuration
- CloudTrail audit logging pipeline design
- CloudWatch security monitoring and ML anomaly detection
- ECS Fargate container deployment and orchestration
- ECR private registry with vulnerability scanning
- CI/CD pipeline design with automated security scanning
- Zero trust security architecture
- NIST 800-53 compliance alignment
- DevSecOps best practices
