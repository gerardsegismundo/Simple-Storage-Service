#!/usr/bin/env python3
"""
Generate a pre-signed S3 URL for a given bucket/key pair.

Usage (CLI):
  python scripts/presigned-urls.py \
    --bucket my-bucket \
    --key path/to/object.jpg \
    --expiration 3600 \
    --http-method GET \
    --region us-east-1

Environment variables (alternatives to CLI args):
  S3_BUCKET, S3_KEY, S3_EXPIRATION, S3_HTTP_METHOD, AWS_REGION

HTTP methods:
  GET  – download / view object
  PUT  – upload object  (use an IAM principal that has PutObject)
"""
import argparse
import os
import sys

import boto3
from botocore.exceptions import (
    ClientError,
    NoCredentialsError,
    ParamValidationError,
)

ALLOWED_METHODS = {"GET", "PUT", "DELETE"}
DEFAULT_EXPIRATION = 3600  # seconds
DEFAULT_REGION = os.environ.get("AWS_REGION", "us-east-1")


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Generate a pre-signed S3 URL.")
    p.add_argument("--bucket", default=os.environ.get("S3_BUCKET"), help="S3 bucket name")
    p.add_argument("--key", default=os.environ.get("S3_KEY"), help="S3 object key")
    p.add_argument(
        "--expiration",
        type=int,
        default=int(os.environ.get("S3_EXPIRATION", DEFAULT_EXPIRATION)),
        help="URL lifetime in seconds (default: 3600)",
    )
    p.add_argument(
        "--http-method",
        default=os.environ.get("S3_HTTP_METHOD", "GET").upper(),
        choices=sorted(ALLOWED_METHODS),
        help="HTTP method for the signed URL",
    )
    p.add_argument("--region", default=DEFAULT_REGION, help="AWS region (default: us-east-1)")
    p.add_argument("--profile", default=None, help="AWS CLI profile name")
    return p.parse_args()


def validate_args(args: argparse.Namespace) -> None:
    missing = [flag for flag, val in [("--bucket", args.bucket), ("--key", args.key)] if not val]
    if missing:
        print(f"ERROR: Missing required argument(s): {', '.join(missing)}", file=sys.stderr)
        print(__doc__, file=sys.stderr)
        sys.exit(1)


def generate_presigned_url(bucket: str, key: str, method: str, expiration: int, region: str, profile: str | None) -> str:
    session = boto3.Session(region_name=region, profile_name=profile)
    client = session.client("s3")

    operation = "get_object" if method == "GET" else "put_object" if method == "PUT" else "delete_object"

    try:
        params: dict[str, str] = {"Bucket": bucket, "Key": key}
        url = client.generate_presigned_url(
            ClientMethod=operation,
            Params=params,
            ExpiresIn=expiration,
            HttpMethod=method if method in {"GET", "PUT", "DELETE"} else None,
        )
    except ClientError as exc:
        print(f"AWS error: {exc}", file=sys.stderr)
        sys.exit(1)
    except (NoCredentialsError, ParamValidationError) as exc:
        print(f"Credential / validation error: {exc}", file=sys.stderr)
        sys.exit(1)

    return url


def main() -> None:
    args = parse_args()
    validate_args(args)

    url = generate_presigned_url(
        bucket=args.bucket,
        key=args.key,
        method=args.http_method,
        expiration=args.expiration,
        region=args.region,
        profile=args.profile,
    )
    print(url)


if __name__ == "__main__":
    main()
