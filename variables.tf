
variable "domain_name" {
  type = string
}
variable "env" {
  type    = string
  default = "dev"
}
variable "website_bucket_name" {
  type = string
}

variable "app_source_dir" {
  type        = string
  description = "The distribution directory to serve via static asset host."
}

variable "alias_domains" {
  type        = list(string)
  description = "The other alias domain names (www.example.com)."
  default     = []
}


# variable "rules" {
#   type    = list
#   default = [
#     {
#       name = "AWS-AWSManagedRulesLinuxRuleSet"
#       priority = 0
#       managed_rule_group_statement_name = "AWS-AWSManagedRulesLinuxRuleSet"
#       managed_rule_group_statement_vendor_name = "AWS"
#       metric_name = "foo_name"
#     },
#     {
#     "Name": "AWS-AWSManagedRulesCommonRuleSet",
#     "Priority": 0,
#     "Statement": {
#       "ManagedRuleGroupStatement": {
#         "VendorName": "AWS",
#         "Name": "AWSManagedRulesCommonRuleSet",
#         "ExcludedRules": [
#           {
#             "Name": "NoUserAgent_HEADER"
#           }
#         ]
#       }
#     },
#     "OverrideAction": {
#       "None": {}
#     },
#     "VisibilityConfig": {
#       "SampledRequestsEnabled": true,
#       "CloudWatchMetricsEnabled": true,
#       "MetricName": "AWS-AWSManagedRulesCommonRuleSet"
#     }
# }
#   ]
# }
