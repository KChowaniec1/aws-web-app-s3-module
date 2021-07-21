terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


###############################################################################
# S3 Bucket for Static Website Hosting
###############################################################################
resource "aws_s3_bucket" "website" {
  bucket        = var.website_bucket_name
  acl           = "public-read"
  force_destroy = true

  tags = {
    Name        = "Website"
    Environment = var.env
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         sse_algorithm = "AES256"
#       }
#     }
#   }

  # Enable versioning
  versioning {
    enabled = true
  }
}

# AWS S3 bucket for www-redirect
resource "aws_s3_bucket" "website_redirect" {
  bucket = "www.${var.website_bucket_name}"
  acl    = "public-read"
  force_destroy = true

  website {
    redirect_all_requests_to = var.website_bucket_name
  }
}
#bucket policy
resource "aws_s3_bucket_policy" "website_policy" {
  bucket = aws_s3_bucket.website.id

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                 "${aws_cloudfront_origin_access_identity.default.iam_arn}"   
                ]
            },
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "${aws_s3_bucket.website.arn}",
                "${aws_s3_bucket.website.arn}/*"
            ]
        }
    ]
}
POLICY
}

#upload assets
resource "aws_s3_bucket_object" "dist" {
  for_each = fileset(var.app_source_dir, "**")
  acl    = "public-read"
  bucket = var.website_bucket_name
  key    = each.value
  source = "${var.app_source_dir}/${each.value}"
  etag   = filemd5("${var.app_source_dir}/${each.value}")
}


###############################################################################
# SSL CERT
###############################################################################
resource "aws_acm_certificate" "acm" {
  # A domain name for which the certificate should be issued
  #provider = aws.us-east-1
  domain_name = var.domain_name

  # Additional names that are supported by this certificate.
  subject_alternative_names = var.alias_domains

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_acm_certificate_validation" "cert" {
#   certificate_arn         = aws_acm_certificate.acm.arn
#   validation_record_fqdns = aws_route53_record.cert_validation[*].fqdn
# }

###############################################################################
# WAF with custom rules
###############################################################################

# resource "aws_wafv2_web_acl" "web_acl" {
#     name        = "web_acl"
#     description = "Web ACL"
#     scope       = "CLOUDFRONT"
#     provider    = aws.us-east
#     default_action {
#         block {}
#     }

#     dynamic "rule" {
#         for_each = toset(var.rules)
#         content {
#             name = rule.value.name
#             priority = rule.value.priority
#             override_action {
#                 count {}
#             }
#         statement {
#             managed_rule_group_statement {
#                 name = rule.value.managed_rule_group_statement_name
#                 vendor_name = rule.value.managed_rule_group_statement_vendor_name
#             }
#         }
#         visibility_config {
#             cloudwatch_metrics_enabled = false
#             metric_name                = rule.value.metric_name
#             sampled_requests_enabled   = false
#         }
#     }
# }


###############################################################################
# CloudFront CDN
###############################################################################

resource "aws_cloudfront_origin_access_identity" "default" {}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.website.website_endpoint
    origin_id   = "website"

    s3_origin_config {
      origin_access_identity ="${aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path}"
    }
  }

  enabled         = true
  depends_on      = [aws_acm_certificate.acm]
  is_ipv6_enabled = true
  comment         = "Managed by Terraform"
  #web_acl_id          = aws_wafv2_web_acl.web_acl.arn
  default_root_object = "index.html"
  aliases             = [var.domain_name]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "website"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 86400
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Environment = var.env
  }

  viewer_certificate {
    # The ARN of the AWS Certificate Manager certificate that you wish to use with this distribution.
    acm_certificate_arn = aws_acm_certificate.acm.arn

    # The minimum version of the SSL protocol that you want CloudFront to use for HTTPS connections.
    minimum_protocol_version = "TLSv1"

    # Specifies how you want CloudFront to serve HTTPS requests.
    ssl_support_method = "sni-only"
  }
}

###############################################################################
# Route 53 Records
###############################################################################

resource "aws_route53_zone" "main" {
  name          = var.domain_name
  comment       = "Managed by Terraform"
  force_destroy = true

  tags = {
    Environment = var.env
  }
}

resource "aws_route53_record" "A" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "CNAME" {
  count = length(var.alias_domains)

  zone_id = aws_route53_zone.main.zone_id
  name    = var.alias_domains[count.index]
  type    = "CNAME"
  records = [aws_cloudfront_distribution.s3_distribution.domain_name]
  ttl     = 86400


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  count = length(var.alias_domains) + 1

  zone_id = aws_route53_zone.main.zone_id
  ttl     = 60

  name    = tolist(aws_acm_certificate.acm.domain_validation_options)[count.index].resource_record_name
  type    = tolist(aws_acm_certificate.acm.domain_validation_options)[count.index].resource_record_type
  records = [tolist(aws_acm_certificate.acm.domain_validation_options)[count.index].resource_record_value]
}