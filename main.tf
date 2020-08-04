variable domain {
  type = string
}

variable "ssl_certificate_arn" {
  type = string
}


provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "infrastructure_bucket" {
  bucket = "cd-assets-infrastructure"
  acl = "private"
}

terraform {
  backend "s3" {
    bucket = "cd-assets-infrastructure"
    key = "terraform.tfstate"
    region = "eu-central-1"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "cesko-digital-assets"
  acl = "private"
}

locals {
  origin_id = "S3-${aws_s3_bucket.bucket.id}"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
}

data "aws_iam_policy_document" "distribution_policy" {
  statement {
    actions = [
      "s3:GetObject"]
    principals {
      type = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
    resources = [
      "${aws_s3_bucket.bucket.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "web_distribution" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.distribution_policy.json
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id = local.origin_id

    s3_origin_config {

      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled = true
  is_ipv6_enabled = true

  aliases = [
    var.domain]

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD"]
    cached_methods = [
      "GET",
      "HEAD"]
    target_origin_id = local.origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
  }


  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.ssl_certificate_arn
    ssl_support_method = "sni-only"
  }
}
