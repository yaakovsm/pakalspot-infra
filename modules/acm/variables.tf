variable "domain_name" {
  description = "The primary domain name for the ACM certificate (e.g., pakalspot.com)"
  type        = string
}

variable "hosted_zone_id" {
  description = "The Route 53 hosted zone ID where DNS validation records will be created"
  type        = string
}

variable "subject_alternative_names" {
  description = "List of subject alternative names (SANs) for the certificate (e.g., ['www.pakalspot.com'])"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

