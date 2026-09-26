# Signal

A small AWS web stack managed entirely with Terraform. It builds a VPC with two public subnets, puts two EC2 web servers running httpd in them, and fronts them with an application load balancer. Route53 DNS is optional.

I built this as the hands-on project for the HashiCorp Certified: Terraform Associate (003) prep course, to get the core workflow (write, plan, apply, destroy) into muscle memory on real AWS resources.

## Architecture

```
                    ┌─────────────┐
  Route53 (optional)│     ALB     │─── target group ───┐
  alias record      └─────────────┘                    │
                                                      ▼
              ┌────────────────────────┐    ┌─────────────────┐
              │  public subnet (AZ a)  │    │ public subnet   │
              │  EC2 web-1 (httpd)     │    │ (AZ b)          │
              └────────────────────────┘    │ EC2 web-2 (httpd│
                                            └─────────────────┘
                        VPC 10.0.0.0/16 + internet gateway
```

Security groups: the ALB accepts HTTP from anywhere, the web servers accept HTTP only from the ALB and SSH only from the CIDR you configure.

## Prerequisites

- Terraform >= 1.5
- An AWS account with credentials configured (`aws configure`), able to create VPC, EC2, ELB, and Route53 resources

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your key pair name and your IP for SSH access, then:

```bash
terraform init
terraform plan
terraform apply
```

Open the `website_url` output in a browser. Tear everything down when you are done:

```bash
terraform destroy
```

## Notes

- `t3.micro` is free-tier eligible, but the ALB is not. Destroy the stack after experimenting so it does not keep billing.
- The Route53 record is only created when `domain_name` is set, and the hosted zone must already exist in your account.
- State is stored locally by default. For anything shared, move it to an S3 backend with state locking.

## Files

| File | Contents |
| ---- | -------- |
| `main.tf` | Terraform and AWS provider setup |
| `variables.tf` | Input variables |
| `network.tf` | VPC, subnets, internet gateway, route table |
| `security.tf` | Security groups for the ALB and web servers |
| `compute.tf` | EC2 instances with httpd installed via user data |
| `alb.tf` | Application load balancer, target group, listener |
| `dns.tf` | Optional Route53 alias record |
| `outputs.tf` | ALB DNS name, instance IDs, VPC ID, site URL |
