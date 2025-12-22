import os
import json
import urllib.request
import urllib.error
import boto3

ssm = boto3.client("ssm")


def get_parameter(name: str, with_decryption: bool = False) -> str:
    response = ssm.get_parameter(Name=name, WithDecryption=with_decryption)
    return response["Parameter"]["Value"]


def lambda_handler(event, context):
    """
    One-time seeding Lambda function.

    Reads seeding status from SSM Parameter Store.
    If already seeded, returns skipped status.
    Otherwise, calls the backend seed endpoint and updates the flag.
    """
    # Environment variables (with defaults for safety)
    flag_param = os.environ.get("FLAG_PARAM", "/pakalspot/seed/seeded")
    api_key_param = os.environ.get("API_KEY_PARAM", "/pakalspot/seed/admin_seed_api_key")

    backend_base_url = os.environ.get("BACKEND_BASE_URL")
    if not backend_base_url:
        return {
            "statusCode": 500,
            "body": json.dumps(
                {
                    "status": "error",
                    "reason": "BACKEND_BASE_URL environment variable is not set",
                }
            ),
        }

    backend_base_url = backend_base_url.rstrip("/")
    seed_url = f"{backend_base_url}/api/admin/seed/init-spots"

    try:
        # Check if already seeded
        try:
            current_flag = get_parameter(flag_param)
            if current_flag.lower() == "true":
                return {
                    "statusCode": 200,
                    "body": json.dumps(
                        {
                            "status": "skipped",
                            "reason": "already seeded",
                            "seed_url": seed_url,
                        }
                    ),
                }
        except ssm.exceptions.ParameterNotFound:
            # Treat as not seeded if the flag parameter does not exist
            pass

        # Read API key from SSM (with decryption)
        try:
            api_key = get_parameter(api_key_param, with_decryption=True)
        except ssm.exceptions.ParameterNotFound:
            return {
                "statusCode": 500,
                "body": json.dumps(
                    {
                        "status": "error",
                        "reason": f"API key parameter {api_key_param} not found in SSM",
                        "seed_url": seed_url,
                    }
                ),
            }

        # Call backend seed endpoint
        request_body = json.dumps({}).encode("utf-8")
        request = urllib.request.Request(
            seed_url,
            data=request_body,
            headers={
                "Content-Type": "application/json",
                "X-Seed-Key": api_key,
            },
            method="POST",
        )

        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                http_code = response.getcode()
                response_body = response.read().decode("utf-8")
        except urllib.error.HTTPError as e:
            error_body = e.read().decode("utf-8") if hasattr(e, "read") else str(e)
            return {
                "statusCode": 200,
                "body": json.dumps(
                    {
                        "status": "error",
                        "http_code": e.code,
                        "response_body": error_body,
                        "seed_url": seed_url,
                    }
                ),
            }
        except urllib.error.URLError as e:
            return {
                "statusCode": 500,
                "body": json.dumps(
                    {
                        "status": "error",
                        "reason": f"URL error calling seed endpoint: {str(e)}",
                        "seed_url": seed_url,
                    }
                ),
            }

        # Only set the flag if response is 2xx
        if 200 <= http_code < 300:
            ssm.put_parameter(
                Name=flag_param,
                Value="true",
                Type="String",
                Overwrite=True,
            )

            return {
                "statusCode": 200,
                "body": json.dumps(
                    {
                        "status": "success",
                        "http_code": http_code,
                        "response_body": response_body,
                        "seed_url": seed_url,
                    }
                ),
            }

        # Non-2xx response: do not set the flag
        return {
            "statusCode": 200,
            "body": json.dumps(
                {
                    "status": "error",
                    "http_code": http_code,
                    "response_body": response_body,
                    "seed_url": seed_url,
                }
            ),
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps(
                {
                    "status": "error",
                    "reason": str(e),
                    "seed_url": seed_url,
                }
            ),
        }
