#!/bin/bash
# Script to build, push, and deploy the backend with migration endpoint

set -e

REGION="us-east-1"
ACCOUNT_ID="182399725157"
ECR_REPO="pakalspot-backend"
APP_RUNNER_SERVICE="pakalspot-backend"
IMAGE_TAG="migration-endpoint-$(date +%Y%m%d-%H%M%S)"

echo "=== Building Docker image ==="
cd /home/yaakovsm/bootcamp/pakalspot/pakalspot-application/pakalspot-app/Backend
docker build -t ${ECR_REPO}:${IMAGE_TAG} .

echo ""
echo "=== Logging into ECR ==="
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

echo ""
echo "=== Tagging image ==="
docker tag ${ECR_REPO}:${IMAGE_TAG} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
docker tag ${ECR_REPO}:${IMAGE_TAG} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO}:latest

echo ""
echo "=== Pushing image to ECR ==="
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO}:latest

echo ""
echo "=== Image pushed successfully! ==="
IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO}:${IMAGE_TAG}"
echo "Image URI: ${IMAGE_URI}"
echo ""
echo "=== Next Steps: Manual App Runner Deployment ==="
echo ""
echo "Since auto_deployments_enabled=false, you need to manually deploy:"
echo ""
echo "Option 1: Via AWS Console"
echo "  1. Go to: https://console.aws.amazon.com/apprunner/home?region=${REGION}#/services"
echo "  2. Click on '${APP_RUNNER_SERVICE}'"
echo "  3. Click 'Deploy' or 'Update service'"
echo "  4. Update the image identifier to: ${IMAGE_URI}"
echo "  5. Deploy"
echo ""
echo "Option 2: Via AWS CLI (update service configuration)"
echo "  SERVICE_ARN=\$(aws apprunner list-services --region ${REGION} --query \"ServiceSummaryList[?ServiceName=='${APP_RUNNER_SERVICE}'].ServiceArn\" --output text)"
echo "  # Then update via console or use AWS SDK"
echo ""
echo "Once deployed, test the migration endpoint with:"
echo "  API_KEY=\$(aws ssm get-parameter --name /pakalspot/seed/admin_seed_api_key --with-decryption --region ${REGION} --query Parameter.Value --output text)"
echo "  curl -X POST \"https://sjizgyvt8n.us-east-1.awsapprunner.com/api/admin/migrations/upgrade\" \\"
echo "    -H \"X-Seed-Key: \$API_KEY\" \\"
echo "    -H \"Content-Type: application/json\""

