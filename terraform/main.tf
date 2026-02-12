provider "aws" {
    region = var.aws_region
}

# S3 buckets

resource "aws_s3_bucket" "raw_logs" {
  bucket = var.raw_bucket_name
}

resource "aws_s3_bucket" "clean_logs" {
  bucket = var.clean_bucket_name
}

# Iam role for lambda 

resource "aws_iam_role" "lambda_role" {
  name = "web_log_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Principal = {
            Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
    }]
  })
}

# attach basic lambda execution permissions
resource "aws_iam_role_policy_attachment" "lambda_basic" {
    role = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# allow lambda to read/write S3
resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "lambda_s3_access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = [
                "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket"
            ]
            Resource = [
                aws_s3_bucket.raw_logs.arn,
                "${aws_s3_bucket.raw_logs.arn}/*",
                aws_s3_bucket.clean_logs.arn,
                "${aws_s3_bucket.clean_logs.arn}/*"
            ]
        }
    ]
  })
}

# lambda function

resource "aws_lambda_function" "log_processor" {
  function_name = "web_log_processor"
  role = aws_iam_role.lambda_role.arn
  handler = "lambda_handler.Lambda_handler"
  runtime = "python3.9"

  filename = "lambda_package.zip"
  source_code_hash = filebase64sha256("lambda_package.zip")

  environment {
    variables = {
      RAW_BUCKET = var.raw_bucket_name
      CLEAN_BUCKET = var.clean_bucket_name
    }
  }
}

# athena database

resource "aws_athena_database" "web_logs_db" {
    name = "web_logs_db"
    bucket = aws_s3_bucket.clean_logs.bucket
  
}