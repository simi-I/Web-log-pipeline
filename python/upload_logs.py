import boto3

s3 = boto3.client("s3")

s3.upload_file(
    "../data/nasa_aug95_c.csv",
    "web-logs-raw-portfolio-unique",
    "nasa_aug95_c.csv"
)

print("Uploaded raw logs to S3.")

