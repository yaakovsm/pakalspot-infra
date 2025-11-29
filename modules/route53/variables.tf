variable "hosted_zone_id" {
  description = "The Route 53 hosted zone ID for the domain"
  type        = string
}

variable "domain_name" {
  description = "The domain name to create the Route 53 record for (e.g., pakalspot.com)"
  type        = string
  default     = "pakalspot.com"
}

variable "cluster_name" {
  description = "The EKS cluster name. Used to find ALB by tags (elbv2.k8s.aws/cluster)."
  type        = string
}

variable "alb_name" {
  description = "The exact name of the ALB to point the Route 53 record to. If not provided, will find ALB by cluster tags. ALB is created by Kubernetes ingress with group.name annotation."
  type        = string
  # Default pattern: k8s-<namespace>-<group-name>-<hash>
  # Since group.name is 'pakalspot', ALB name will start with k8s-pakalspot-
  # User can provide the exact name, or leave empty to auto-detect by tags
  default = ""
}

variable "alb_arn" {
  description = "The ARN of the ALB. If provided, this takes precedence over alb_name and tag-based lookup."
  type        = string
  default     = ""
}

variable "enable_route53_record" {
  description = "Whether to create the Route 53 record"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

