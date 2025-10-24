# Step-by-Step: Deploying the HIPAA Free-Tier Application on AWS

## 🧩 1. Prerequisites

Make sure you have the following in place before you begin.

### 🖥️ Local setup

- **AWS Account** with Free Tier eligibility (new or low-usage account)
- **AWS CLI** installed and configured (`aws configure`) with IAM credentials that have:
  - AdministratorAccess or sufficient Terraform provisioning rights
- **Terraform** installed (>= v1.5.0)
- **Existing EC2 Key Pair** in your target region (us-east-1 by default)

**Check Terraform:**
```bash
terraform -version
```

**Check AWS CLI:**
```bash
aws sts get-caller-identity
```

## 📂 2. Project Setup

Navigate to the free-tier directory:

```bash
cd free-tier
```

You should now see:
- `main.tf`
- `variables.tf`
- `terraform.tfvars.example`
- `outputs.tf`
- `modules/` directory

## ⚙️ 3. Configure Variables

Copy the example file and edit it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` and adjust:

```hcl
region           = "us-east-1"
key_name         = "your-aws-keypair-name"
ssh_allowed_cidr = "YOUR.PUBLIC.IP/32"
alerts_email     = "you@example.com"
```

💡 **Tip:** Restrict SSH access to your own IP instead of 0.0.0.0/0 for better security.

## 🏗️ 4. Initialize Terraform

Initialize the working directory to download required providers and modules:

```bash
terraform init
```

You should see something like:
```
- Downloading hashicorp/aws...
Terraform has been successfully initialized!
```

## 🔍 5. Validate and Plan

**Validate your syntax and resources:**
```bash
terraform validate
```

**Then plan the deployment:**
```bash
terraform plan -out hipaa-plan.out
```

This shows what Terraform will create:
- ✅ VPC, subnets, security groups
- ✅ EC2 instance (t3.micro)
- ✅ RDS PostgreSQL (db.t3.micro, 20GB)
- ✅ S3 bucket (AES256 encrypted)
- ✅ CloudWatch + SNS for alerts
- ✅ SSM patch management setup

## 🚀 6. Apply the Configuration

Deploy your environment:

```bash
terraform apply "hipaa-plan.out"
```

You'll be prompted to confirm — type **yes**.

Terraform will:
- Provision the networking stack (VPC, subnets, etc.)
- Launch your EC2 and RDS instances
- Create your S3 bucket, CloudWatch alarms, and SNS subscription

⏳ **Deployment takes about 5–10 minutes.**

## 📬 7. Confirm SNS Subscription

You'll receive an email from AWS SNS asking you to confirm your subscription. 

**Click "Confirm subscription"** to activate alert notifications.

## 🧠 8. Access Your Application

After apply completes:

```bash
terraform output
```

You'll get:
- `vpc_id`
- `app_instance_id`
- `db_endpoint`

**Use this to find the EC2 public IP for SSH or testing:**

```bash
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw app_instance_id) \
  --query 'Reservations[*].Instances[*].PublicIpAddress' \
  --output text
```

Or simply:
```bash
terraform output app_instance_public_ip
```

**SSH in:**
```bash
ssh -i /path/to/your-key.pem ec2-user@<public-ip>
```

## 🔍 9. Post-Deployment Verification

Run the verification script to check your deployment:

```bash
cd ..
./verify_hipaa_free_tier.sh
```

The script will verify:
- ✅ EC2 instance is t3.micro (Free Tier eligible)
- ✅ RDS instance is db.t3.micro (Free Tier eligible)
- ✅ S3 bucket uses AES256 encryption
- ✅ CloudWatch alarms are configured
- ✅ SNS subscription is confirmed

**Expected output:**
```
==============================================
 HIPAA Free-Tier Environment Verification
==============================================

🔍 Checking EC2 instance...
✅ EC2 instance is t3.micro (Free Tier eligible)

🔍 Checking RDS instance...
✅ RDS instance is db.t3.micro (Free Tier eligible)

🔍 Checking S3 bucket encryption...
✅ S3 bucket 'afratech-free-tier-bucket' uses AES256 encryption (Free)

🔍 Checking CloudWatch alarms...
✅ CloudWatch alarms are configured (basic alarms are free).

🔍 Checking SNS subscriptions...
✅ SNS subscription confirmed.
```

## 🧹 10. Cleanup (Optional)

When you're done and want to avoid charges:

```bash
cd free-tier
terraform destroy
```

This tears down all provisioned resources cleanly.

## 🔒 11. Post-Deployment Checklist (HIPAA Prep for Production)

Even though this setup is free-tier–safe, for actual HIPAA compliance you'll eventually need to:

| Requirement | AWS Service (Paid) | Description |
|-------------|-------------------|-------------|
| Data Encryption at Rest | AWS KMS (CMK) | Replace AES256 with CMK for compliance logging |
| Intrusion Detection | GuardDuty | Enable continuous threat monitoring |
| Web Protection | AWS WAF | Protect against SQLi/XSS |
| Automated Backups | AWS Backup | For RDS, EBS, S3 recovery |
| Access Logging | CloudTrail | Enable organization-wide auditing |

## ✅ You now have:

- ✅ A fully working HIPAA-ready application baseline deployed entirely under the AWS Free Tier
- ✅ Security essentials (VPC isolation, SSM patching, encrypted S3, monitoring)
- ✅ No recurring charges unless you exceed Free Tier limits

## 📊 Infrastructure Components

### VPC & Networking
- VPC CIDR: `10.0.0.0/16`
- 2 Public Subnets (across 2 AZs)
- 2 Private Subnets (across 2 AZs)
- Internet Gateway
- Route Tables

### Compute
- EC2: t3.micro with Amazon Linux 2023
- SSM-enabled for patch management
- Encrypted EBS volumes
- SSH restricted to your IP

### Database
- RDS PostgreSQL 15.4
- db.t3.micro instance
- 20GB encrypted storage
- 7-day backup retention
- Deployed in private subnets

### Storage
- S3 bucket with AES256 encryption
- Versioning enabled
- Public access blocked
- Lifecycle policies

### Monitoring
- CloudWatch alarms for CPU, status checks, storage
- SNS email notifications
- Application log groups

### Security & Compliance
- SSM patch management (Sundays 2 AM UTC)
- Patch scanning every 6 hours
- IMDSv2 enabled
- Encrypted data at rest and in transit

## 🆘 Troubleshooting

**Terraform init fails:**
- Check AWS credentials: `aws sts get-caller-identity`
- Ensure internet connectivity

**Apply fails with "key pair not found":**
- Create key pair in EC2 console first
- Update `key_name` in terraform.tfvars

**Can't SSH to instance:**
- Check security group allows your IP
- Verify key pair permissions: `chmod 400 your-key.pem`
- Get instance public IP: `terraform output app_instance_public_ip`

**Email alerts not working:**
- Check spam folder for SNS confirmation
- Click the confirmation link in the email

## 📝 Additional Configuration

All configurations are in `main.tf`. See [CONFIGURATION.md](../CONFIGURATION.md) for customization options.
