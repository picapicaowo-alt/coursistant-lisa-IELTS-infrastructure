locals {
  uploads_bucket_name   = "${var.name_prefix}-uploads-${var.account_id}"
  artifacts_bucket_name = "${var.name_prefix}-artifacts-${var.account_id}"
  audit_bucket_name     = "${var.name_prefix}-audit-${var.account_id}"
  cloudtrail_arn        = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${var.account_id}:trail/${var.cloudtrail_name}"
}

data "aws_partition" "current" {}

resource "aws_s3_bucket" "uploads" {
  #checkov:skip=CKV_AWS_144:Cross-region replication is intentionally excluded from the Tokyo-only test data boundary.
  bucket = local.uploads_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    DataClass = "private-application-objects"
  })
}

resource "aws_s3_bucket" "artifacts" {
  #checkov:skip=CKV_AWS_144:Git is the source authority and immutable test artifacts remain in the approved Tokyo region.
  bucket = local.artifacts_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    DataClass = "immutable-deployment-artifacts"
  })
}

resource "aws_s3_bucket" "audit" {
  #checkov:skip=CKV_AWS_144:Test audit logs remain in Tokyo; cross-region transfer requires a separate compliance decision.
  #checkov:skip=CKV_AWS_145:ALB access-log delivery requires S3-managed default encryption; CloudTrail objects explicitly use the environment KMS key.
  bucket = local.audit_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = merge(var.tags, {
    DataClass = "audit-logs"
  })
}

resource "aws_s3_bucket_notification" "this" {
  for_each = {
    uploads   = aws_s3_bucket.uploads.id
    artifacts = aws_s3_bucket.artifacts.id
    audit     = aws_s3_bucket.audit.id
  }

  bucket      = each.value
  eventbridge = true
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each = {
    uploads   = aws_s3_bucket.uploads.id
    artifacts = aws_s3_bucket.artifacts.id
    audit     = aws_s3_bucket.audit.id
  }

  bucket                  = each.value
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  for_each = {
    uploads   = aws_s3_bucket.uploads.id
    artifacts = aws_s3_bucket.artifacts.id
    audit     = aws_s3_bucket.audit.id
  }

  bucket = each.value

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = {
    uploads   = aws_s3_bucket.uploads.id
    artifacts = aws_s3_bucket.artifacts.id
    audit     = aws_s3_bucket.audit.id
  }

  bucket = each.value

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "application" {
  for_each = {
    uploads   = aws_s3_bucket.uploads.id
    artifacts = aws_s3_bucket.artifacts.id
  }

  bucket = each.value

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# ALB access-log delivery supports S3-managed encryption. Keep the audit bucket
# private and encrypted without making log delivery depend on a customer KMS key.
resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    id     = "clean-incomplete-and-noncurrent"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = var.uploads_noncurrent_expiration_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "clean-incomplete-and-noncurrent"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = var.artifacts_noncurrent_expiration_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_lifecycle_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id

  rule {
    id     = "expire-test-audit-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.audit_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_logging" "uploads" {
  bucket        = aws_s3_bucket.uploads.id
  target_bucket = aws_s3_bucket.audit.id
  target_prefix = "s3-access/uploads/"

  depends_on = [aws_s3_bucket_policy.audit]
}

resource "aws_s3_bucket_logging" "artifacts" {
  bucket        = aws_s3_bucket.artifacts.id
  target_bucket = aws_s3_bucket.audit.id
  target_prefix = "s3-access/artifacts/"

  depends_on = [aws_s3_bucket_policy.audit]
}

resource "aws_s3_bucket_cors_configuration" "uploads" {
  count = length(var.cors_allowed_origins) > 0 ? 1 : 0

  bucket = aws_s3_bucket.uploads.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD", "POST", "PUT"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 300
  }
}

data "aws_iam_policy_document" "uploads" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.uploads.arn,
      "${aws_s3_bucket.uploads.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  policy = data.aws_iam_policy_document.uploads.json
}

data "aws_iam_policy_document" "artifacts" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.artifacts.arn,
      "${aws_s3_bucket.artifacts.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  policy = data.aws_iam_policy_document.artifacts.json
}

data "aws_iam_policy_document" "audit" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.audit.arn,
      "${aws_s3_bucket.audit.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid     = "AllowCloudTrailAclCheck"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]
    resources = [
      aws_s3_bucket.audit.arn,
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.cloudtrail_arn]
    }
  }

  statement {
    sid     = "AllowCloudTrailWrite"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.audit.arn}/cloudtrail/AWSLogs/${var.account_id}/*",
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.cloudtrail_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid     = "AllowAlbLogDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.audit.arn}/alb/AWSLogs/${var.account_id}/*",
    ]

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }

  statement {
    sid     = "AllowS3AccessLogDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.audit.arn}/s3-access/*",
    ]

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        aws_s3_bucket.uploads.arn,
        aws_s3_bucket.artifacts.arn,
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "audit" {
  bucket = aws_s3_bucket.audit.id
  policy = data.aws_iam_policy_document.audit.json
}
