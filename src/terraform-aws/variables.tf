variable application_name {
  description = "Please define application name (eg. my-application)"
}

variable environment {
  description = "please define environment (eg. development)"
  default     = "development"
}

variable instance_type {
  description = "Please define ec2 instance (eg. t2.nano)"
}

variable instance_ami {
  default = "ami-87de806c" // 14.04 LTS

  # default = "ami-daba31b5" // 17.04 LTS
  # https://cloud-images.ubuntu.com/locator/ec2/
}

variable private_key_path {
  description = "ec2 ssh connection private key (eg. ~/.ssh/private.pem)"
}

variable ansible_cfg {
  default = "../ansible/ansible.cfg"
}

variable aws_region {
  default = "eu-central-1"
}

variable rds_password {
  description = "Please define RDS MySQL password (min 8 length)"
  default     = "rdspassword1"
}

variable website_name {
  description = "Please define the wordpress website name (eg. domain.com)"
}

variable aws_profile {
  description = "Please input which AWS profile should be used in this deployment"
}

variable ec2_key_name {
  description = "type a existing aws ec2 keypair"
}

variable ec2_user {
  description = "ec2 ssh connection username"
  default     = "ubuntu"
}

variable instance_count {
  description = "Please input how many instances to be deployed in load balancer (eg. 2)"
}
