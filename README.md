# AWS Enterprise Security Lab

## Overview
This project deploys a secure, enterprise-grade AWS environment using Terraform Infrastructure as Code (IaC). It simulates real-world cloud infrastructure aligned with zero trust principles, NIST 800-53 compliance standards, and DevSecOps best practices.

## Architecture

### Phase 1: Network Foundation
- **VPC** — Isolated network with a defined address space (10.0.0.0/16)
- **Public Subnet** — Resources that require internet access (10.0.1.0/24)
- **Private Subnet** — Isolated resources with no internet path (10.0.2.0/24)
- **Internet Gateway** — Single controlled entry and exit point to the internet
- **Route Tables** — Public subnet routes to IGW, private subnet has no internet route
- **Security Groups** — Zero trust deny-by-default rules with microsegmentation between tiers

## Security Design Decisions
- **Deny by default:** No inbound traffic permitted unless explicitly allowed
- **Microsegmentation:** Private security group only accepts traffic from public security group
- **No internet path for private tier:** Private route table has no IGW route — isolated by design
- **Infrastructure as Code:** All resources version controlled and reproducible
- **No hardcoded credentials:** Authentication via AWS CLI, secrets never in source control
- **Default tagging:** Every resource tagged with Project, Environment, and ManagedBy for cost tracking and ownership

## Technologies Used
- Terraform v1.15.2
- Amazon Web Services (AWS)
- AWS CLI
- HCL (HashiCorp Configuration Language)
- Git / GitHub

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

Deploy the infrastructure:

    terraform apply

Tear down when done:

    terraform destroy

## Compliance Alignment
- NIST 800-53 SC-7 (Boundary Protection)
- NIST 800-53 AC-3 (Access Enforcement)
- Zero Trust Architecture principles
- Least privilege network access controls

## Skills Demonstrated
- Enterprise AWS network architecture
- Infrastructure as Code with Terraform
- Zero trust security design
- Cloud security best practices aligned with DevSecOps
- Version controlled infrastructure management