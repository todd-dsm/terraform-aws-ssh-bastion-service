#Get aws account number 
data "aws_caller_identity" "current" {}

#get aws region for use later in plan
data "aws_region" "current" {}

#get list of AWS Availability Zones which can be accessed by an AWS account within the region for use later in plan
data "aws_availability_zones" "available" {}

#get vpc data to whitelist internal CIDR range for Load Balaacer
data "aws_vpc" "main" {
  id = "${var.vpc}"
}

##########################
#Create bastion service role with policies - only needed once per aws account
##########################

module "iam_service_role" {
  source         = "./iam_service_role"
  s3_bucket_name = "${var.s3_bucket_name}"

  # create_iam_service_role = "${var.create_iam_service_role}"
}

# ##################
# # security group for bastion_host
# ##################

resource "aws_security_group" "instance" {
  name        = "bastion_service_host"
  description = "Allow ssh-host and ssh-bastion access to bastion_service_host"

  # SSH access from whitelist IP ranges for sshd service containers 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.cidr_blocks_whitelist_service}"
  }

  # SSH access from whitelist IP ranges - to be used for host sshd - useful for debugging
  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_blocks_whitelist_host}"]
  }

  # SSH access fromrom anywhere within vpc to accomodate l - to be used for host sshd
  ingress {
    from_port   = 2222
    to_port     = 2222
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.main.cidr_block}"]
  }

  # SSH access from anywhere within vpc to accomodate load balancer for sshd service containers 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.main.cidr_block}"]
  }

  # Permissive egress policy because we want users to be able to install their own packages 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # vpc_id = "${var.vpc}"
}

##########################
#Query for most recent AMI of type debian for use as host
##########################

data "aws_ami" "debian" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-stretch-hvm-x86_64-*"]
  }

  owners = ["379101102735"] # Debian
}

############################
#Launch configuration for service host
############################

resource "aws_launch_configuration" "bastion-service-host" {
  name_prefix          = "bastion-service-host"
  image_id             = "${data.aws_ami.debian.id}"
  instance_type        = "${var.bastion_instance_type}"
  iam_instance_profile = "bastion_service_profile"

  # associate_public_ip_address = "false"

  #https://github.com/hashicorp/terraform/issues/575
  #https://github.com/hashicorp/terraform/commit/3b67537dfabc1a65eb17e92849da5e64737daae3
  security_groups = ["${aws_security_group.instance.id}"]
  user_data = "${data.template_file.bastion_host.rendered}"
  key_name  = "${var.bastion_service_host_key_name}"
  lifecycle {
    create_before_destroy = true
  }
}

#######################################################
# ASG section
#######################################################

resource "aws_autoscaling_group" "bastion-service-asg" {
  # availability_zones   = ["${data.aws_availability_zones.available.names}"]
  name_prefix          = "bastion-service-asg"
  max_size             = "${var.asg_max}"
  min_size             = "${var.asg_min}"
  desired_capacity     = "${var.asg_desired}"
  launch_configuration = "${aws_launch_configuration.bastion-service-host.name}"
  vpc_zone_identifier  = ["${var.subnets_asg}"]
  target_group_arns    = ["${aws_lb_target_group.bastion-service-target-group.arn}"]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "bastion-service-host"
    propagate_at_launch = "true"
  }
}

#######################################################
# Network load balancer section
#######################################################

resource "aws_lb" "bastion-service-nlb" {
  name               = "bastion-service-nlb"
  load_balancer_type = "network"
  subnets            = ["${var.subnets_nlb}"]
  idle_timeout       = "${var.nlb_idle_timeout}"
}

#######################
#aws_lb_target_group
#######################
resource "aws_lb_target_group" "bastion-service-target-group" {
  name     = "bastion-service-target-group"
  port     = 22
  protocol = "TCP"
  vpc_id   = "${var.vpc}"

  # health_check {
  #   healthy_threshold   = "${var.nlb_healthy_threshold}"
  #   unhealthy_threshold = "${var.nlb_unhealthy_threshold}"
  #   port                = 22
  #   protocol            = "TCP"

  #   interval = "${var.nlb_interval}"
  # }
}

#######################
#aws_lb_listener
#######################

resource "aws_lb_listener" "bastion-service-listener" {
  load_balancer_arn = "${aws_lb.bastion-service-nlb.arn}"
  port              = "22"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.bastion-service-target-group.arn}"
    type             = "forward"
  }
}

#######################
# Copy templates files to bastion host
####################

# userdata for bastion host
data "template_file" "bastion_host" {
  template = "${file("${path.module}/user_data_template/bastion_host_cloudinit_config.tpl")}"

  vars {
    bastion_host_name               = "${var.environment_name}-${data.aws_region.current.name}"
    iam_authorized_keys_command_url = "${var.iam_authorized_keys_command_url}"
  }
}

####################################################
# DNS Section
###################################################

resource "aws_route53_record" "bastion_service" {
  zone_id = "${var.route53_zone_id}"
  name    = "${var.environment_name}-${data.aws_region.current.name}-bastion-service.${var.dns_domain}"
  type    = "A"

  alias {
    name                   = "${aws_lb.bastion-service-nlb.dns_name}"
    zone_id                = "${aws_lb.bastion-service-nlb.zone_id}"
    # evaluate_target_health = true
  }
}

####################################################
# Outputs Section
###################################################

output "service_dns_entry" {
  description = "dns-registered url for bastion service"
  value       = "${var.environment_name}-${data.aws_region.current.name}-bastion-service.${var.dns_domain}"
}
