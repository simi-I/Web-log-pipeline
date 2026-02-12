import boto3

s3 = boto3.client("s3")

s3.upload_file(
    "nasa_logs.txt",
    "web-logs-raw-portfolio",
    "nasa_logs.txt"
)

print("Uploaded raw logs to S3.")