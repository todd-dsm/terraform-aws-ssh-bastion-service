variable "bastion_instance_type" {
  description = "The virtual hardware to be used for the bastion service host"
  default     = "t2.micro"
}

variable "cidr_blocks_whitelist_host" {
  description = "range(s) of incoming IP addresses to whitelist for the HOST"
  type        = "list"
  default     = []
}

variable "cidr_blocks_whitelist_service" {
  description = "range(s) of incoming IP addresses to whitelist for the SERVICE"
  type        = "list"
}

variable "environment_name" {
  description = "the name of the environment that we are deploying to"
  default     = "staging"
}

variable "vpc" {
  description = "ID for Virtual Private Cloud to apply security policy and deploy stack to"
}

variable "bastion_service_host_key_name" {
  description = "AWS ssh key *.pem to be used for ssh access to the bastion service host"
}

variable "subnets_nlb" {
  type        = "list"
  description = "list of subnets for load balancer - typically this will be public subnets"
  default     = []
}

variable "subnets_asg" {
  type        = "list"
  description = "list of subnets for autoscaling group - typically this will be private subnets"
  default     = []
}

variable "dns_domain" {
  description = "The domain used for Route53 records"
}

variable "route53_zone_id" {
  description = "Route53 zoneId"
}

variable "iam_authorized_keys_command_url" {
  description = "location for our compiled Go binary - see https://github.com/Fullscreen/iam-authorized-keys-command"
}

# variable "create_iam_service_role" {
#   type        = "string"
#   description = "Whether or not we call the iam_service_role module to create the bastion)servce_role (Boolean value)"
#   default     = "1"
# }

variable "s3_bucket_name" {
  description = "the name of the s3 bucket where we are storing our go binary"
}

##############################
#nlb ASG variables
##############################
variable "nlb_healthy_threshold" {
  type        = "string"
  description = "Healthy threshold for nlb"
  default     = "2"
}

variable "nlb_unhealthy_threshold" {
  type        = "string"
  description = "Unhealthy threshold for nlb"
  default     = "2"
}

variable "nlb_timeout" {
  type        = "string"
  description = "timeout for nlb"
  default     = "3"
}

variable "nlb_interval" {
  type        = "string"
  description = "interval for nlb health check"
  default     = "30"
}

variable "nlb_idle_timeout" {
  type        = "string"
  description = "The time in seconds that the connection is allowed to be idle"
  default     = "300"
}

variable "asg_max" {
  type        = "string"
  description = "Max numbers of bastion-service hosts in ASG"
  default     = "2"
}

variable "asg_min" {
  type        = "string"
  description = "Min numbers of bastion-service hosts in ASG"
  default     = "1"
}

variable "asg_desired" {
  type        = "string"
  description = "Desired numbers of bastion-service hosts in ASG"
  default     = "1"
}
