output "bucket_name" {
  value = aws_s3_bucket.photo_bucket.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.photo_metadata.name
}
