# Random suffix to make bucket name unique (highly recommended)
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket for ALB access logs
resource "aws_s3_bucket" "bos_alb_logs" {
  bucket = "bos-alb-logs-891377135193-${random_string.bucket_suffix.result}"

  force_destroy = true  # optional for lab cleanup
}

# Ownership controls (required for ALB logs)
resource "aws_s3_bucket_ownership_controls" "bos_alb_logs" {
  bucket = aws_s3_bucket.bos_alb_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Bucket policy - allows ELB service to write logs
# resource "aws_s3_bucket_policy" "alb_logs_policy" {
#   bucket = aws_s3_bucket.alb_logs.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "AllowELBLogsDelivery"
#         Effect    = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::127311923021:root"  # Critical for us-east-1
#         }
#         Action    = "s3:PutObject"
#         Resource  = [
#           "arn:aws:s3:::bos-alb-logs-891377135193/AWSLogs/891377135193/*",          # no prefix
#           "arn:aws:s3:::bos-alb-logs-891377135193/alb-logs/AWSLogs/891377135193/*"  # if prefix="alb-logs"
#         ]
#       },
#       {
#         Sid       = "AllowDeliveryAclCheck"
#         Effect    = "Allow"
#         Principal = {
#           Service = "delivery.logs.amazonaws.com"
#         }
#         Action    = "s3:GetBucketAcl"
#         Resource  = "arn:aws:s3:::bos-alb-logs-891377135193"
#       }
#     ]
#   })
# }

# resource "aws_s3_bucket" "alb_logs" {
#   bucket = "bos-alb-logs-891377135193"
#   # ... other settings (force_destroy if needed for lab, SSE-S3 recommended)
# }

# resource "aws_s3_bucket_policy" "alb_logs_policy" {
#   bucket = aws_s3_bucket.alb_logs.id   # or just "bos-alb-logs-891377135193" if not managing bucket here

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid       = "AWSLogDeliveryWrite"
#         Effect    = "Allow"
#         Principal = { Service = "logdelivery.elasticloadbalancing.amazonaws.com" }
#         Action    = "s3:PutObject"
#         Resource  = "arn:aws:s3:::bos-alb-logs-891377135193/AWSLogs/891377135193/*"
#         Condition = {
#           StringEquals = {
#             "s3:x-amz-acl" = "bucket-owner-full-control"
#           }
#         }
#       },
#       # Optional fallback for older behavior / some regions (us-east-1 often needs this too)
#       {
#         Sid       = "AWSLogDeliveryAclCheck"
#         Effect    = "Allow"
#         Principal = { Service = "delivery.logs.amazonaws.com" }
#         Action    = "s3:GetBucketAcl"
#         Resource  = "arn:aws:s3:::bos-alb-logs-891377135193"
#       }
#     ]
#   })
# }

# resource "aws_s3_bucket_ownership_controls" "alb_logs" {
#   bucket = aws_s3_bucket.alb_logs.id
#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

############################################
# S3 bucket for ALB access logs
############################################

# Explanation: This bucket is bos’s log vault—every visitor to the ALB leaves footprints here.
resource "aws_s3_bucket" "bos_alb_logs_bucket01" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = "${var.project_name}-alb-logs-${data.aws_caller_identity.bos_self01.account_id}"

  tags = {
    Name = "${var.project_name}-alb-logs-bucket01"
  }
}

# Explanation: Block public access—bos does not publish the ship’s black box to the galaxy.
resource "aws_s3_bucket_public_access_block" "bos_alb_logs_pab01" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket                  = aws_s3_bucket.bos_alb_logs_bucket01[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# # Explanation: Bucket ownership controls prevent log delivery chaos—bos likes clean chain-of-custody.
resource "aws_s3_bucket_ownership_controls" "bos_alb_logs_owner01" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.bos_alb_logs_bucket01[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# # Explanation: TLS-only—bos growls at plaintext and throws it out an airlock.
resource "aws_s3_bucket_policy" "bos_alb_logs_policy01" {
  count = var.enable_alb_access_logs ? 1 : 0

  bucket = aws_s3_bucket.bos_alb_logs_bucket01[0].id

  # NOTE: This is a skeleton. Students may need to adjust for region/account specifics.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.bos_alb_logs_bucket01[0].arn,
          "${aws_s3_bucket.bos_alb_logs_bucket01[0].arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid    = "AllowELBPutObject"
        Effect = "Allow"
        Principal = {
          Service = "elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.bos_alb_logs_bucket01[0].arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.bos_self01.account_id}/*"
      }
    ]
  })
}