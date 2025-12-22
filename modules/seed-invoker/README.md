# Seed Invoker Module

This Terraform module creates a Lambda function that performs one-time seeding of the backend database via the CloudFront API endpoint.

## Prerequisites

**IMPORTANT**: Before applying this module, you must create the admin seed API key parameter in SSM Parameter Store:

```bash
aws ssm put-parameter \
  --name /pakalspot/seed/admin_seed_api_key \
  --type SecureString \
  --value "your-secret-key-here" \
  --description "Admin seed API key for one-time database seeding"
```

The parameter must exist as a SecureString at `/pakalspot/seed/admin_seed_api_key` before Terraform can read it via the data source.

## How It Works

1. The Lambda function checks the SSM parameter `/pakalspot/seed/seeded` to see if seeding has already occurred.
2. If the flag is `"true"`, the Lambda returns a skipped status without calling the endpoint.
3. If the flag is `"false"` or missing, the Lambda:
   - Reads the admin seed API key from SSM Parameter Store
   - Calls the seed endpoint: `POST https://<cloudfront-domain>/api/admin/seed/init-spots`
   - Includes the `X-Seed-Key` header with the API key
   - On success (2xx response): Sets the flag to `"true"` and returns success
   - On failure (non-2xx): Raises an error and does NOT set the flag

## Resetting the Seed Flag

To re-run seeding (e.g., after database reset), set the SSM parameter back to `"false"`:

```bash
aws ssm put-parameter \
  --name /pakalspot/seed/seeded \
  --type String \
  --value "false" \
  --overwrite
```

After resetting, the next Terraform apply will trigger the Lambda again (if triggers change) or you can manually invoke it.

## Manual Lambda Invocation

To manually invoke the Lambda function for debugging:

```bash
aws lambda invoke \
  --function-name pakalspot-seed-invoker \
  --region <aws-region> \
  /tmp/seed-result.json

cat /tmp/seed-result.json
```

The output will show:
- `{"status":"skipped","reason":"already seeded"}` if already seeded
- `{"status":"success","http_code":200,"response_body":"..."}` on successful seeding
- `{"status":"error","reason":"..."}` on failure

## Module Inputs

- `cloudfront_domain` (string, default: "d1356pm1pxuqc3.cloudfront.net"): CloudFront distribution domain
- `aws_region` (string, required): AWS region for resources
- `common_tags` (map(string), optional): Common tags to apply to all resources

## Module Outputs

- `lambda_function_name`: Name of the Lambda function
- `ssm_flag_param_name`: Name of the SSM parameter storing the seeded flag
- `ssm_api_key_param_name`: Name of the SSM parameter storing the admin seed API key

## IAM Permissions

The Lambda function requires:
- CloudWatch Logs: Basic execution role (for logging)
- SSM: `GetParameter` on both `/pakalspot/seed/seeded` and `/pakalspot/seed/admin_seed_api_key`
- SSM: `PutParameter` only on `/pakalspot/seed/seeded` (to update the flag)

## Triggering

The Lambda is automatically invoked via a `null_resource` with `local-exec` provisioner after Terraform apply. The invocation is triggered when:
- CloudFront domain changes
- Lambda source code hash changes

The `null_resource` has proper `depends_on` to ensure CloudFront, App Runner, SSM parameters, and Lambda exist before invocation.
