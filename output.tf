output "website_bucket_id" {
  value = "${aws_s3_bucket.website.id}"
}

output "website_bucket_arn" {
  value = "${aws_s3_bucket.website.arn}"
}

output "website_bucket_hosted_zone_id" {
  value = "${aws_s3_bucket.website.hosted_zone_id}"
}

output "website_bucket_regional_domain_name" {
  value = "${aws_s3_bucket.website.bucket_regional_domain_name}"
}


output "cloudfront_distribution_domain_name" {
  value = "${aws_cloudfront_distribution.s3_distribution.domain_name}"
}

output "cloudfront_distribution_id" {
  value = "${aws_cloudfront_distribution.s3_distribution.id}"
}

output "cloudfront_distribution_arn" {
  value = "${aws_cloudfront_distribution.s3_distribution.arn}"
}

output "web_acl_id" {
  description = "The ARN of the WAF WebACL."
  value       = aws_wafv2_web_acl.web_acl.arn
}