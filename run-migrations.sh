#!/bin/bash
# Script to run database migrations by temporarily allowing local IP access to RDS

set -e

REGION="us-east-1"
RDS_SG_ID="sg-083e42dc0b917cc2f"
MY_IP=$(curl -s https://checkip.amazonaws.com)

echo "Your IP: $MY_IP"
echo "Adding temporary ingress rule to RDS security group..."

# Add temporary ingress rule
RULE_ID=$(aws ec2 authorize-security-group-ingress \
    --group-id "$RDS_SG_ID" \
    --protocol tcp \
    --port 5432 \
    --cidr "${MY_IP}/32" \
    --region "$REGION" \
    --query 'SecurityGroupRules[0].SecurityGroupRuleId' \
    --output text 2>&1)

echo "Rule added: $RULE_ID"
echo "Waiting 5 seconds for rule to propagate..."
sleep 5

# Get database credentials
SECRET_ARN="arn:aws:secretsmanager:us-east-1:182399725157:secret:rds!db-f91da479-3037-457d-b3c8-e40bbb769f25-P7XZAl"
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "$SECRET_ARN" --region "$REGION" --query SecretString --output text | python3 -c "import sys, json; print(json.load(sys.stdin).get('password', ''))")
DB_HOST="pakalspotdb.ckho4oo4ocby.us-east-1.rds.amazonaws.com"
DB_USER="pakalspot"
DB_NAME="pakalspot-db"
DB_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:5432/${DB_NAME}"

# Get backend secrets
BACKEND_SECRETS=$(aws secretsmanager get-secret-value --secret-id /pakalspot/backend --region "$REGION" --query SecretString --output text)
SECRET_KEY=$(echo "$BACKEND_SECRETS" | python3 -c "import sys, json; print(json.load(sys.stdin).get('SECRET_KEY', ''))")
S3_ACCESS_KEY=$(echo "$BACKEND_SECRETS" | python3 -c "import sys, json; print(json.load(sys.stdin).get('S3_ACCESS_KEY', ''))")
S3_SECRET_KEY=$(echo "$BACKEND_SECRETS" | python3 -c "import sys, json; print(json.load(sys.stdin).get('S3_SECRET_KEY', ''))")

echo "Running migrations..."
cd /home/yaakovsm/bootcamp/pakalspot/pakalspot-application/pakalspot-app/Backend

docker run --rm \
    -e DB_URL="$DB_URL" \
    -e SECRET_KEY="$SECRET_KEY" \
    -e S3_ACCESS_KEY="$S3_ACCESS_KEY" \
    -e S3_SECRET_KEY="$S3_SECRET_KEY" \
    pakalspot-backend-migrations \
    alembic upgrade head

echo ""
echo "Migrations completed successfully!"
echo "Removing temporary ingress rule..."

# Remove the rule
aws ec2 revoke-security-group-ingress \
    --group-id "$RDS_SG_ID" \
    --security-group-rule-ids "$RULE_ID" \
    --region "$REGION" 2>&1 > /dev/null

echo "Temporary rule removed. Done!"

