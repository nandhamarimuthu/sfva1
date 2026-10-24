output "queue_url" {
  value = aws_sqs_queue.work.url
}

output "bucket_name" {
  value = aws_s3_bucket.artifacts.bucket
}

output "lambda_name" {
  value = aws_lambda_function.worker.function_name
}
