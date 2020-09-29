variable domain {
  type = string
}

variable "ssl_certificate_arn" {
  type = string
}


provider "aws" {
  region = "eu-central-1"
}

terraform {
  backend "s3" {
    bucket = "cd-assets-terraform-backend"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "data-cesko-digital-manual"
  acl    = "private"

  cors_rule {
    allowed_headers = [
      "Authorization"]
    allowed_methods = [
      "GET",
      "HEAD"]
    allowed_origins = [
      "*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "automated_bucket" {
  bucket = "data-cesko-digital"
  acl    = "private"

  cors_rule {
    allowed_headers = [
      "Authorization"]
    allowed_methods = [
      "GET",
      "HEAD"]
    allowed_origins = [
      "*"]
    expose_headers  = []
    max_age_seconds = 3000
  }
}

locals {
  origin_id           = "S3-${aws_s3_bucket.bucket.id}"
  automated_origin_id = "S3-${aws_s3_bucket.automated_bucket.id}"
  group_origin_id     = "S3-cesko-digital-all-assets"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
}

data "aws_iam_policy_document" "distribution_policy" {
  statement {
    actions   = [
      "s3:GetObject"]
    principals {
      type        = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
    resources = [
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "automated_distribution_policy" {
  statement {
    actions   = [
      "s3:GetObject"]
    principals {
      type        = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn
      ]
    }
    resources = [
      "${aws_s3_bucket.automated_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "web_distribution" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.distribution_policy.json
}

resource "aws_s3_bucket_policy" "web_distribution_automated" {
  bucket = aws_s3_bucket.automated_bucket.id
  policy = data.aws_iam_policy_document.automated_distribution_policy.json
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin_group {
    origin_id = local.group_origin_id

    failover_criteria {
      status_codes = [
        403,
        404,
        500,
        502]
    }

    member {
      origin_id = local.origin_id
    }

    member {
      origin_id = local.automated_origin_id
    }
  }

  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = local.origin_id

    s3_origin_config {

      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = aws_s3_bucket.automated_bucket.bucket_regional_domain_name
    origin_id   = local.automated_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  aliases = [
    var.domain]

  default_cache_behavior {
    allowed_methods  = [
      "GET",
      "HEAD"]
    cached_methods   = [
      "GET",
      "HEAD"]
    target_origin_id = local.group_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }


  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.ssl_certificate_arn
    ssl_support_method  = "sni-only"
  }

  custom_error_response {
    error_code = 403
    error_caching_min_ttl = 10
    response_page_path = "/index.html"
  }
}
