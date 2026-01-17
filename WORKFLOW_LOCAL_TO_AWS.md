# Workflow: Local Development → AWS Deployment

This guide covers best practices for working locally with docker-compose and then deploying to AWS with Terraform.

## Overview

**Workflow Pattern:**
1. Destroy AWS infrastructure (optional, for clean slate)
2. Work locally with docker-compose
3. Apply changes to AWS when ready

## Important: What Gets Preserved vs Destroyed

### ✅ Preserved (Not Managed by Terraform)
- **Terraform State**: Stored in S3 (`terraform-pakalspot-backend-bucket`), persists across destroys
- **Secrets Manager**: `/pakalspot/backend` secret (created separately, not in Terraform)
- **SSM Parameters**: `/pakalspot/seed/admin_seed_api_key` (created separately, not in Terraform)
- **ECR Images**: Docker images in ECR (not destroyed by Terraform)
- **ACM Certificate**: Certificate for pakalspot.com (referenced, not created by Terraform)

### ⚠️ Destroyed (Managed by Terraform)
- **RDS Database**: All data will be lost (unless you take a snapshot first)
- **S3 Buckets**: Frontend and photos buckets (content will be lost)
- **App Runner Service**: Service will be recreated
- **CloudFront Distribution**: Will be recreated (takes 15-20 minutes to deploy)
- **Lambda Function**: Seed invoker Lambda will be recreated
- **VPC, Subnets, Security Groups**: All networking will be recreated
- **IAM Roles and Policies**: Will be recreated

## Step-by-Step Workflow

### Phase 1: Prepare for Local Development

#### 1.1 Backup Important Data (Optional)

If you need to preserve any data:

```bash
# Backup RDS database (if needed)
DB_IDENTIFIER=$(terraform output -raw rds_endpoint 2>/dev/null | cut -d'.' -f1 || echo "pakalspotdb")
aws rds create-db-snapshot \
  --db-instance-identifier ${DB_IDENTIFIER} \
  --db-snapshot-identifier pakalspot-pre-destroy-$(date +%Y%m%d) \
  --region us-east-1 \
  --profile tf-user

# Backup S3 bucket contents (if needed)
FRONTEND_BUCKET=$(terraform output -raw frontend_s3_bucket_name)
PHOTOS_BUCKET=$(terraform output -raw photos_s3_bucket_name)

# Download frontend files
aws s3 sync s3://${FRONTEND_BUCKET} ./backups/frontend-$(date +%Y%m%d)/ --region us-east-1 --profile tf-user

# Download photos (if needed)
aws s3 sync s3://${PHOTOS_BUCKET} ./backups/photos-$(date +%Y%m%d)/ --region us-east-1 --profile tf-user
```

#### 1.2 Export Important Configuration

```bash
cd /home/yaakovsm/bootcamp/pakalspot/pakalspot-infra/environments/dev

# Export outputs for reference
terraform output -json > ../../terraform-outputs-$(date +%Y%m%d).json

# Export current variable values
cp terraform.tfvars ../../terraform.tfvars.backup-$(date +%Y%m%d)
```

#### 1.3 Destroy Infrastructure

```bash
cd /home/yaakovsm/bootcamp/pakalspot/pakalspot-infra/environments/dev

# Review what will be destroyed
terraform plan -destroy

# Destroy (this will take 10-15 minutes)
terraform destroy

# Note: Terraform state in S3 is NOT destroyed, so you can recreate everything
```

**Important Notes:**
- RDS deletion may take 10-15 minutes (even with `skip_final_snapshot = true`)
- CloudFront distribution deletion takes 15-20 minutes
- Some resources may have deletion protection - check `terraform.tfvars`
- If destroy fails, check for resources that need manual cleanup

### Phase 2: Local Development with Docker Compose

#### 2.1 Start Local Environment

```bash
cd /home/yaakovsm/bootcamp/pakalspot/pakalspot-application/pakalspot-app

# Start all services
docker-compose up -d

# Check services are running
docker-compose ps

# View logs
docker-compose logs -f backend
```

#### 2.2 Run Migrations Locally

```bash
# Access backend container
docker-compose exec backend bash

# Inside container, run migrations
alembic upgrade head

# Or from host
docker compose exec backend alembic upgrade head
```

#### 2.3 Seed Database Locally (Optional)

```bash
# If you have seed data locally
docker compose exec backend python app/db/seed.py

# Or use the seed endpoint (if migration endpoint is deployed)
API_KEY="your-local-api-key"
curl -X POST "http://localhost:8000/api/admin/seed/init-spots" \
  -H "X-Seed-Key: ${API_KEY}" \
  -H "Content-Type: application/json"
```

#### 2.4 Develop and Test Locally

- Frontend: `http://localhost:3000`
- Backend API: `http://localhost:8000`
- Database: `localhost:5432`
- API Docs: `http://localhost:8000/docs`

**Local Development Tips:**
- Use hot-reload volumes in docker-compose for code changes
- Test migrations locally before deploying
- Test seed endpoint locally if you added it
- Verify all environment variables work locally

### Phase 3: Deploy to AWS

#### 3.1 Prepare for Deployment

```bash
cd /home/yaakovsm/bootcamp/pakalspot/pakalspot-infra/environments/dev

# Ensure you have the latest Terraform state
terraform init

# Verify configuration
terraform validate
terraform fmt -check
```

#### 3.2 Update Terraform Variables (if needed)

Check `terraform.tfvars` for any changes:
- ECR image URI (if you built new images)
- Database configuration
- Any other infrastructure changes

#### 3.3 Apply Infrastructure

```bash
# Review changes
terraform plan

# Apply (this will recreate everything)
terraform apply

# Monitor progress - this takes 15-20 minutes for:
# - VPC and networking (2-3 minutes)
# - RDS creation (10-15 minutes)
# - App Runner service (5-10 minutes)
# - CloudFront distribution (15-20 minutes)
```

#### 3.4 Post-Deployment Steps

```bash
# 1. Run database migrations
APP_RUNNER_URL=$(terraform output -raw app_runner_service_url)
API_KEY=$(aws ssm get-parameter --name /pakalspot/seed/admin_seed_api_key --with-decryption --region us-east-1 --query Parameter.Value --output text)

curl -X POST "${APP_RUNNER_URL}/api/admin/migrations/upgrade" \
  -H "X-Seed-Key: ${API_KEY}" \
  -H "Content-Type: application/json"

# 2. Seed database (via Lambda or manually)
# Lambda will auto-invoke, or manually:
aws ssm put-parameter --name /pakalspot/seed/seeded --type String --value "false" --overwrite --region us-east-1
aws lambda invoke --function-name pakalspot-seed-invoker --region us-east-1 /tmp/seed-result.json
cat /tmp/seed-result.json

# 3. Upload frontend to S3
FRONTEND_BUCKET=$(terraform output -raw frontend_s3_bucket_name)
cd /home/yaakovsm/bootcamp/pakalspot/pakalspot-application/pakalspot-app/Frontend
# Build frontend first, then:
aws s3 sync dist/ s3://${FRONTEND_BUCKET}/ --region us-east-1 --profile tf-user

# 4. Invalidate CloudFront cache
CF_DIST_ID=$(terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id ${CF_DIST_ID} --paths "/*" --region us-east-1 --profile tf-user
```

## Best Practices

### 1. State Management

**✅ DO:**
- Keep Terraform state in S3 (already configured)
- Use state locking (already configured with `use_lockfile = true`)
- Never commit `.tfstate` files to git
- Use `terraform state` commands to inspect state

**❌ DON'T:**
- Delete the S3 backend bucket (contains state)
- Manually edit state files
- Run `terraform destroy` on the backend bucket

### 2. Secrets Management

**✅ DO:**
- Keep secrets in Secrets Manager (not in Terraform)
- Use SSM Parameter Store for seed API key
- Reference secrets via data sources, don't create them in Terraform
- Use `terraform.tfvars` for non-sensitive config (gitignored)

**❌ DON'T:**
- Commit secrets to git
- Hardcode secrets in Terraform files
- Store secrets in Terraform state (use data sources instead)

### 3. Resource Naming

**✅ DO:**
- Use consistent naming: `pakalspot-{resource}-{environment}`
- Use tags for resource organization
- Keep resource names predictable for easier management

**❌ DON'T:**
- Use random suffixes that change on recreate
- Hardcode resource names in application code

### 4. Local Development

**✅ DO:**
- Use docker-compose for local development
- Match local environment variables to production where possible
- Test migrations locally before deploying
- Use local database for development (don't connect to AWS RDS from local)

**❌ DON'T:**
- Point local app to AWS resources (use local equivalents)
- Commit local environment files
- Use production secrets in local development

### 5. Deployment Strategy

**✅ DO:**
- Test infrastructure changes with `terraform plan` first
- Apply during low-traffic periods (if production)
- Monitor CloudWatch logs after deployment
- Verify all services are healthy after apply

**❌ DON'T:**
- Destroy production infrastructure during business hours
- Skip `terraform plan` review
- Apply without verifying variable values

## Quick Reference Commands

### Destroy Everything
```bash
cd environments/dev
terraform destroy
```

### Start Local Development
```bash
cd pakalspot-application/pakalspot-app
docker-compose up -d
docker-compose exec backend alembic upgrade head
```

### Deploy to AWS
```bash
cd environments/dev
terraform apply
# Then run migrations and seed (see section 3.4)
```

### Check What Will Be Destroyed
```bash
terraform plan -destroy
```

### Preserve State While Destroying
```bash
# State is in S3, so it's automatically preserved
# Just run: terraform destroy
# State file remains in S3 for future applies
```

## Troubleshooting

### Destroy Hangs on RDS
```bash
# RDS deletion can take 10-15 minutes
# Check status:
aws rds describe-db-instances --db-instance-identifier pakalspotdb --region us-east-1 --profile tf-user --query 'DBInstances[0].DBInstanceStatus'
```

### Destroy Hangs on CloudFront
```bash
# CloudFront deletion takes 15-20 minutes
# Check status:
CF_DIST_ID=$(terraform output -raw cloudfront_distribution_id)
aws cloudfront get-distribution --id ${CF_DIST_ID} --region us-east-1 --profile tf-user --query 'Distribution.Status'
```

### Can't Destroy Due to Dependencies
```bash
# Some resources may have dependencies
# Use -target to destroy in order:
terraform destroy -target=module.seed_invoker
terraform destroy -target=module.cloudfront_frontend
terraform destroy -target=module.app_runner
terraform destroy -target=module.rds
# etc.
```

### State Locked
```bash
# If state is locked (another process is running):
# Check for lock file in S3:
aws s3api head-object --bucket terraform-pakalspot-backend-bucket --key "dev/terraform.tfstate.lock" --region us-east-1

# If stuck, you may need to manually remove lock (use with caution):
aws s3 rm s3://terraform-pakalspot-backend-bucket/dev/terraform.tfstate.lock --region us-east-1
```

## Alternative: Selective Destroy

If you only want to destroy specific resources:

```bash
# Destroy only App Runner (keep RDS, S3, etc.)
terraform destroy -target=module.app_runner

# Destroy only networking (keep data resources)
terraform destroy -target=module.networking

# Recreate specific resource
terraform apply -target=module.app_runner
```

## Cost Considerations

**Resources that cost money even when "stopped":**
- RDS: Charges for storage even if instance is stopped
- NAT Gateway: Charges per hour when exists
- EBS volumes: Charges for storage
- S3: Charges for storage (minimal)

**To minimize costs during local development:**
- Destroy RDS if not needed (saves ~$15-30/month)
- Destroy NAT Gateway if not needed (saves ~$32/month)
- Keep S3 buckets (minimal cost, ~$0.023/GB/month)
- Destroy CloudFront (no charges when destroyed)

## Recommended Workflow for Occasional Use

Since you're doing this occasionally:

1. **Before Destroy:**
   - Export any important outputs
   - Note current resource IDs/ARNs for reference
   - Ensure secrets in Secrets Manager are up to date

2. **During Local Development:**
   - Work normally with docker-compose
   - Test all changes locally
   - Commit code changes to git

3. **Before Reapply:**
   - Review Terraform changes
   - Update `terraform.tfvars` if needed
   - Ensure ECR images are built and pushed (if code changed)

4. **After Reapply:**
   - Run migrations
   - Run seeding
   - Upload frontend to S3
   - Invalidate CloudFront cache
   - Verify everything works

This workflow ensures a clean, predictable cycle between local development and AWS deployment.


