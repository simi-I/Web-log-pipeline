import boto3
import re
import pandas as pd
from io import StringIO

s3 = boto3.client("s3")

pattern = re.compile(
    r'(?P<ip>\S+) .* \[(?P<timestamp>.*?)\]'
    r'"(?P<method>\S+) (?P<endpoint>\S+) .*" '
    r'(?P<status>\d+) (?P<bytes>\d+)'
)

def lambda_handler(event, context):
    obj = s3.get_object(Bucket="web-logs-raw-portfolio", Key="nasa_logs.txt")
    logs = obj["Body"].read().decode("utf-8").splitlines()

    parsed = []
    for line in logs:
        match = pattern.search(line)
        if match:
            parsed.append(match.groupdict)

    df = pd.DataFrame(parsed)

    csv_buffer = StringIO()
    df.to_csv(csv_buffer, index=False)

    s3.put_object (
        Bucket = "web-logs-clean-portfolio",
        Key = "clean_logs.csv",
        Body = csv_buffer.getvalue()
    )

    return {"status": "success"}