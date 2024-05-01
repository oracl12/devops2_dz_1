variable "domain_name" {
  description = "The domain name for your website"
}

variable "bucket_name" {
  description = "The name of the S3 bucket for your website"
}

variable "route53_zone_id" {
  description = "The Route 53 zone ID where the DNS records will be added"
}