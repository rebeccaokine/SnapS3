provider "aws" {
  region = "us-east-1"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "photo_bucket" {
  bucket = "photo-uploader-demo-${random_id.bucket_suffix.hex}"
  force_destroy = true  # So the bucket can be deleted even if not empty

  tags = {
    Name = "Photo Uploader Bucket"
  }
}

resource "aws_dynamodb_table" "photo_metadata" {
  name         = "PhotoMetadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "photo_name"

  attribute {
    name = "photo_name"
    type = "S"
  }

  tags = {
    Name = "Photo Metadata Table"
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "photo_uploader_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "photo_uploader_lambda_policy"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["dynamodb:PutItem"],
        Resource = aws_dynamodb_table.photo_metadata.arn
      },
      {
        Effect = "Allow",
        Action = ["s3:GetObject"],
        Resource = "${aws_s3_bucket.photo_bucket.arn}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "photo_metadata_lambda" {
  function_name = "photo-metadata-writer"
  runtime       = "python3.12"
  handler       = "handler.lambda_handler"
  filename      = "${path.module}/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")

  role = aws_iam_role.lambda_exec_role.arn

  environment {
    variables = {
      DDB_TABLE_NAME = aws_dynamodb_table.photo_metadata.name
    }
  }

  depends_on = [aws_iam_role_policy.lambda_policy]
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.photo_metadata_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.photo_bucket.arn
}

resource "aws_s3_bucket_notification" "s3_trigger_lambda" {
  bucket = aws_s3_bucket.photo_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.photo_metadata_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg"  # Only trigger for .jpg files
  }

  depends_on = [aws_lambda_permission.allow_s3]
}