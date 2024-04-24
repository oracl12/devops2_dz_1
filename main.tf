provider "aws" {
  region = "us-east-1"
}

# TLS
resource "aws_acm_certificate" "example" {
  domain_name = "doa.pp.ua"
  validation_method = "DNS"

  tags = {
    Name = "ExampleCertificate"
  }
}

# s3
resource "aws_s3_bucket" "website" {
  bucket = "aboba123-32"
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.website.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:PutBucketPolicy",
        Resource  = "arn:aws:s3:::${aws_s3_bucket.website.bucket}"
      },
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "arn:aws:s3:::${aws_s3_bucket.website.bucket}/*"
      }
    ]
  })
}

resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.website.bucket
  key = "index.html"
  content = "<html><head><title>My Website</title></head><body><h1>Welcome to My Website!</h1></body></html>"

  content_type = "text/html"
}


# Cloudfront
resource "aws_cloudfront_distribution" "website_distribution" {
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name 
    origin_id   = "S3-${aws_s3_bucket.website.id}"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id = "S3-${aws_s3_bucket.website.id}"

    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.example.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  aliases = ["doa.pp.ua"]
}

resource "aws_route53_record" "website_record" {
  zone_id = "Z0338044DWIAFDMCXLYH"  # Замініть на ідентифікатор вашої зони в Route53
  name    = element(aws_acm_certificate.example.domain_validation_options[*].resource_record_name, 0)
  type    = "CNAME"
  ttl     = "300"
  records = [element(aws_acm_certificate.example.domain_validation_options[*].resource_record_value, 0)]
}

resource "aws_route53_record" "example" {
  zone_id = "Z0338044DWIAFDMCXLYH"
  name    = "doa.pp.ua"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.website_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.website_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}