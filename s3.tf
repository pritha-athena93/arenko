resource "random_id" "alb_logs_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.service}-alb-logs-${random_id.alb_logs_suffix.hex}"
  force_destroy = var.s3_force_destroy

  tags = {
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "alb-logs-tiered-retention"
    status = "Enabled"

    # Empty filter means the rule applies to all objects in the bucket.
    filter {}

    # Standard for the first 30 days — fast access for recent debugging.
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Glacier Instant Retrieval from day 90 — millisecond retrieval, ~80% cheaper.
    # Useful for incident investigations and compliance without paying for standard storage.
    transition {
      days          = 90
      storage_class = "GLACIER_IR"
    }

    # Delete after 1 year. Extend this if your compliance policy requires longer retention.
    expiration {
      days = 365
    }

    # Clean up old versions quickly — these are logs, not source of truth data.
    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    # Prevent cost accumulation from abandoned multipart uploads.
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  # Must wait for public access block before applying policy, otherwise AWS
  # will reject policies that reference public-access-restricted buckets.
  depends_on = [aws_s3_bucket_public_access_block.alb_logs]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowALBAccessLogs"
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/AWSLogs/*"
      },
      {
        Sid       = "DenyNonSSL"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.alb_logs.arn,
          "${aws_s3_bucket.alb_logs.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
