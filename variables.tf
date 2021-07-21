
variable "domain_name" {
  type = string
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

variable "managed_rules" {
  type = list(object({
    name            = string
    priority        = number
    override_action = string
    excluded_rules  = list(string)
  }))
  description = "List of Managed WAF rules."
  default = [
    {
      name            = "AWSManagedRulesCommonRuleSet",
      priority        = 10
      override_action = "none"
      excluded_rules  = []
    }
  ]
}

variable "ip_sets_rules" {
  type = list(object({
    name            = string
    priority        = number
    action          = string
    ip_set_arn      = string
  }))
  description = "List of custom IP set WAF rules."
  default = []
}
