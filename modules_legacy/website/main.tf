# S3 Bucket in us-east-2
resource "aws_s3_bucket" "site" {
  provider = aws.ohio
  bucket   = "resume.warta.org"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "404.html"
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  provider = aws.ohio
  bucket   = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "PublicReadGetObject",
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.site.arn}/*"
    }]
  })
}

resource "aws_s3_bucket_ownership_controls" "ownership" {
  provider = aws.ohio
  bucket   = aws_s3_bucket.site.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  provider = aws.ohio
  bucket   = aws_s3_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ACM in us-east-1 (required for CloudFront)
resource "aws_acm_certificate" "cert" {
  provider          = aws.virginia
  domain_name       = "yourdomain.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  provider = aws.ohio
  name     = aws_acm_certificate.cert.domain_validation_options[0].resource_record_name
  type     = aws_acm_certificate.cert.domain_validation_options[0].resource_record_type
  zone_id  = "ROUTE53_ZONE_ID"
  records  = [aws_acm_certificate.cert.domain_validation_options[0].resource_record_value]
  ttl      = 300
}

resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

# CloudFront (global service but requires cert in us-east-1)
resource "aws_cloudfront_distribution" "cdn" {
  provider            = aws.virginia
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.site.website_endpoint
    origin_id   = "s3-website-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-website-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = ["yourdomain.com"]
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.cdn.domain_name
}
