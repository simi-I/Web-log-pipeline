# Web Log Pipeline

A complete data pipeline for processing and visualizing NASA web server logs (August 1995) using AWS services (S3, Lambda, Athena) and Amazon QuickSight.

**Dataset**: 1.57M web requests from NASA servers | **Time Period**: August 1995

---

## 🏗️ Architecture

```
S3 (Raw Logs)
    ↓
Lambda Function (Data Processing)
    ↓
S3 (Cleaned/Processed Logs)
    ↓
Athena (SQL Queries) + QuickSight (Visualizations)
```

---

## 📊 Features

- **Data Processing**: AWS Lambda serverless function to clean and transform raw logs
- **Data Storage**: Processed logs stored in Parquet format in S3
- **Analytics**: Query processed data using Amazon Athena
- **Visualizations**: 8 interactive dashboards in Amazon QuickSight:
  - HTTP Status Code Distribution
  - Traffic Over Time (Hourly)
  - Top 15 Requesting Hosts
  - Response Size Distribution
  - Response Size by Status Code
  - HTTP Request Methods
  - Top Resource Types
  - Traffic Heatmap (Day vs Hour)

---

## 🛠️ Tech Stack

- **AWS Services**: S3, Lambda, IAM, Athena, QuickSight
- **Infrastructure as Code**: Terraform
- **Languages**: Python 3.11, SQL
- **Data Format**: CSV → Parquet

---

## 📁 Project Structure

```
Web log pipeline/
├── README.md                    # This file
├── QUICKSIGHT_MANUAL.md         # Manual QuickSight setup guide
├── data/
│   └── nasa_aug95_c.csv         # Raw web logs (1.5GB)
├── python/
│   ├── upload_logs.py           # S3 upload script
│   └── lambda_handler.py         # Lambda function for data processing
├── terraform/
│   ├── main.tf                  # AWS resources (Lambda, S3, IAM)
│   ├── variables.tf             # Configuration variables
│   └── outputs.tf               # Terraform outputs
```

---

## 🚀 Quick Start

### Prerequisites
- AWS Account with appropriate permissions
- Terraform installed
- Python 3.11+
- AWS CLI configured

### 1. Deploy Infrastructure

```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

This creates:
- S3 buckets for raw and processed logs
- Lambda function with necessary IAM permissions
- Outputs bucket names for reference

### 2. Upload Raw Data

```bash
cd python/
python3 upload_logs.py
```

Uploads `nasa_aug95_c.csv` to S3 raw logs bucket.

### 3. Process Logs with Lambda

The Lambda function automatically triggers when a new file is uploaded to the raw bucket. It:
- Reads raw CSV logs
- Parses and validates data
- Converts to Parquet format
- Uploads to cleaned bucket

### 4. Query with Athena

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS `weblog`.`weblogtable` (
  `requestinghost` string,
  `timestamp` timestamp,
  `request` string,
  `status` int,
  `bytes` int,
  `method` string,
  `endpoint` string,
  `protocol` string,
  `is_error` boolean
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat' 
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION 's3://web-logs-clean-portfolio-unique/processed/'
TBLPROPERTIES ('classification' = 'parquet');

-- Query example: Top endpoints
SELECT endpoint, COUNT(*) AS hits
FROM weblogtable
GROUP BY endpoint
ORDER BY hits DESC
LIMIT 10;
```

### 5. Visualize in QuickSight

See [QUICKSIGHT_MANUAL.md](QUICKSIGHT_MANUAL.md) for step-by-step instructions to create 8 interactive visualizations.

---

## ⚙️ Lambda Configuration

The Lambda function required specific configurations to handle the large dataset:

### Lambda Layers
- **Layer Used**: `AWSSDKPandas-Python311` (AWS-managed)
- **Purpose**: Pre-built pandas library for efficient CSV/Parquet processing
- **Benefits**: Reduces deployment package size and improves cold start time

```terraform
layers = [
  "arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python311:26"
]
```

### Increased Resources
- **Runtime**: Python 3.11
- **Memory**: 2,996 MB (3GB)
- **Timeout**: 400 seconds (6.67 minutes)

**Why increased specs?**
- Dataset size: 1.57M rows × 5 columns
- Parquet encoding is computationally intensive
- Pandas dataframe requires significant memory for processing
- 400s timeout allows time for S3 I/O and transformation

---

## 🔧 Troubleshooting

### Lambda Issues

**"Task timed out"**
- Increase timeout (done: 400 seconds)
- Increase memory allocation (done: 2,996 MB)
- Consider streaming large files instead of loading all at once

**"Module 'pandas' not found"**
- Ensure Lambda layer is attached (already configured in Terraform)
- Layer must match Python runtime version (3.11)

### QuickSight Connection Issues

When connecting QuickSight to data sources, you may encounter connection errors. AWS provides comprehensive troubleshooting:

📖 **Reference**: [AWS QuickSight Troubleshooting Guide](https://docs.aws.amazon.com/quicksight/latest/user/troubleshoot-connection-issues.html)



