provider "aws" {
  region = var.aws_region
}

# ---------------------------
# S3 BUCKETS
# ---------------------------

resource "aws_s3_bucket" "raw_logs" {
  bucket = var.raw_bucket_name
}

resource "aws_s3_bucket" "clean_logs" {
  bucket = var.clean_bucket_name
}

# ---------------------------
# IAM ROLE FOR LAMBDA
# ---------------------------

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

# Basic Lambda execution (CloudWatch logs)
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# S3 access policy
resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "lambda_s3_access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
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
    }]
  })
}

# ---------------------------
# LAMBDA FUNCTION
# ---------------------------

resource "aws_lambda_function" "log_processor" {
  function_name = "web_log_processor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_handler.lambda_handler"
  runtime       = "python3.11"

  filename         = "lambda_package.zip"
  source_code_hash = filebase64sha256("lambda_package.zip")

  # Pass bucket name to Python (best practice)
  environment {
    variables = {
      CLEAN_BUCKET = var.clean_bucket_name
    }
  }
}

# ---------------------------
# ALLOW S3 TO TRIGGER LAMBDA
# ---------------------------

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.raw_logs.arn
}

# ---------------------------
# S3 EVENT TRIGGER
# ---------------------------

resource "aws_s3_bucket_notification" "trigger_lambda" {
  bucket = aws_s3_bucket.raw_logs.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.log_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}