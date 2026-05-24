import json


def lambda_handler(event, context):
    print("Received S3 event:", json.dumps(event))

    records = event.get("Records", [])
    for record in records:
        s3 = record.get("s3", {})
        bucket = s3.get("bucket", {}).get("name")
        key = s3.get("object", {}).get("key")
        print(f"New object uploaded: bucket={bucket}, key={key}")

    return {
        "statusCode": 200,
        "body": json.dumps({"message": "S3 event processed"})
    }
