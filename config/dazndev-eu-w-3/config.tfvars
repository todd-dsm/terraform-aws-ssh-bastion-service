bastion_instance_type = "t2.xlarge"
vpc = "vpc-3e0df257"
subnets_nlb = ["subnet-3e916a57", "subnet-5bafb323", "subnet-940735de"]
subnets_asg = ["subnet-3e916a57", "subnet-5bafb323", "subnet-940735de"]
bastion_service_host_key_name = "dazndev-joshua-kite-euw3"
iam_authorized_keys_command_url = "s3://dazn-dev-eu-w-2-bastion-service-files/iam-authorized-keys-command"
s3_bucket_name = "dazn-dev-eu-w-2-bastion-service-files"
cidr_blocks_whitelist_service = ["217.111.163.174/32"]
cidr_blocks_whitelist_host = ["217.111.163.174/32"]
dns_domain = "dazndev.com"
route53_zone_id = "Z11O5UHZCWYOX"
environment_name = "dazndev"