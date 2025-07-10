# Create a public hosted zone for the subdomain
resource "aws_route53_zone" "resume_subdomain" {
  name = "resume.warta.org"
}

# Example A record (for website hosting)
resource "aws_route53_record" "resume_a" {
  zone_id = aws_route53_zone.resume_subdomain.zone_id
  name    = "site58.resume.warta.org"
  type    = "A"
  ttl     = 300
  records = ["23.235.23.74"] # Replace with your actual IP or use an alias to S3/CloudFront/ALB
}

# # Example MX record (for email)
# resource "aws_route53_record" "resume_mx" {
#   zone_id = aws_route53_zone.resume_subdomain.zone_id
#   name    = "resume.warta.org"
#   type    = "MX"
#   ttl     = 3600
#   records = [
#     "10 mail.resume.warta.org.",
#   ]
# }

# # (Optional) Add mail server A record
# resource "aws_route53_record" "mail_a" {
#   zone_id = aws_route53_zone.resume_subdomain.zone_id
#   name    = "mail.resume.warta.org"
#   type    = "A"
#   ttl     = 300
#   records = ["1.2.3.5"] # Replace with your mail server IP
# }
