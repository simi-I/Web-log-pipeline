import boto3
import pandas as pd
from io import BytesIO, StringIO

s3 = boto3.client("s3")

def lambda_handler(event, context):

    record = event["Records"][0]
    bucket = record["s3"]["bucket"]["name"]
    key = record["s3"]["object"]["key"]

    obj = s3.get_object(Bucket=bucket, Key=key)
    data = obj["Body"].read().decode("utf-8")

    df = pd.read_csv(StringIO(data))

    # Rename columns for consistency
    df = df.rename(columns={
        "datetime": "timestamp",
        "response_size": "bytes"
    })

    # Parse request column
    request_parts = df["request"].str.split(" ", expand=True)
    df["method"] = request_parts[0]
    df["endpoint"] = request_parts[1]
    df["protocol"] = request_parts[2]

    # Cleaning
    df["status"] = df["status"].astype(int)
    df["bytes"] = df["bytes"].fillna(0).astype(int)

    # Feature engineering
    df["is_error"] = df["status"] >= 400


    df['timestamp'] = pd.to_datetime(df['timestamp'])
    # Convert to Parquet
    parquet_buffer = BytesIO()
    df.to_parquet(parquet_buffer, index=False)

    # Remove file extension from original key to avoid double extension
    key_without_ext = key.rsplit('.', 1)[0]

    s3.put_object(
        Bucket="web-logs-clean-portfolio-unique",
        Key=f"processed/{key_without_ext}.parquet",
        Body=parquet_buffer.getvalue()
    )

    return {"status": "success"}