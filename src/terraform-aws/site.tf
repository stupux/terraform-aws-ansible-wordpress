provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

# Variables for VPC module
module "vpc_subnets" {
  source               = "./modules/vpc_subnets"
  name                 = "${var.application_name}"
  environment          = "${var.environment}"
  enable_dns_support   = true
  enable_dns_hostnames = true
  vpc_cidr             = "172.16.0.0/16"
  public_subnets_cidr  = "172.16.10.0/24,172.16.20.0/24"
  private_subnets_cidr = "172.16.30.0/24,172.16.40.0/24"
  azs                  = "eu-central-1a,eu-central-1b"
}

module "ssh_sg" {
  source            = "./modules/ssh_sg"
  name              = "${var.application_name}"
  environment       = "${var.environment}"
  vpc_id            = "${module.vpc_subnets.vpc_id}"
  source_cidr_block = "0.0.0.0/0"
}

module "web_sg" {
  source            = "./modules/web_sg"
  name              = "${var.application_name}"
  environment       = "${var.environment}"
  vpc_id            = "${module.vpc_subnets.vpc_id}"
  source_cidr_block = "0.0.0.0/0"
}

module "elb_sg" {
  source      = "./modules/elb_sg"
  name        = "${var.application_name}"
  environment = "${var.environment}"
  vpc_id      = "${module.vpc_subnets.vpc_id}"
}

module "rds_sg" {
  source            = "./modules/rds_sg"
  name              = "${var.application_name}"
  environment       = "${var.environment}"
  vpc_id            = "${module.vpc_subnets.vpc_id}"
  security_group_id = "${module.web_sg.web_sg_id}"
}

module "ec2" {
  source            = "./modules/ec2"
  name              = "${var.application_name}"
  environment       = "${var.environment}"
  server_role       = "web"
  ami_id            = "${var.instance_ami}"                                        // ubuntu 14.04 LTS
  ec2_user          = "${var.ec2_user}"
  private_key_path  = "${var.private_key_path}"
  key_name          = "${var.ec2_key_name}"
  count             = "${var.instance_count}"
  security_group_id = "${module.ssh_sg.ssh_sg_id},${module.web_sg.web_sg_id}"
  subnet_id         = "${module.vpc_subnets.public_subnets_id}"
  instance_type     = "${var.instance_type}"
  user_data         = "#!/bin/bash\napt-get -y update\napt-get -y install nginx\n"
  ansible_cfg       = "${var.ansible_cfg}"
}

module "rds" {
  source            = "./modules/rds"
  name              = "${var.application_name}"
  environment       = "${var.environment}"
  storage           = "5"
  engine_version    = "5.6.27"
  db_name           = "wordpress"
  username          = "root"
  password          = "${var.rds_password}"
  security_group_id = "${module.rds_sg.rds_sg_id}"
  subnet_ids        = "${module.vpc_subnets.private_subnets_id}"
}

module "elb" {
  source             = "./modules/elb"
  name               = "${var.application_name}"
  environment        = "${var.environment}"
  security_groups    = "${module.elb_sg.elb_sg_id}"
  availability_zones = "eu-central-1a,eu-central-1b"
  subnets            = "${module.vpc_subnets.public_subnets_id}"
  instance_id        = "${module.ec2.ec2_id}"
}

resource "null_resource" "ansible" {
  # hack to run this resource everytime everytime
  triggers {
    key              = "${uuid()}"
    cluster_instance = "${module.ec2.ec2_id}"
  }

  # waiting ssh, then local-exec below
  provisioner "remote-exec" {
    inline = ["echo remote-exec"]

    connection {
      type        = "ssh"
      host        = "${element(split(",", module.ec2.public_dns), var.instance_count)}"
      user        = "${var.ec2_user}"
      private_key = "${file(var.private_key_path)}"
    }
  }

  provisioner "local-exec" {
    command = "echo DB_HOSTNAME: ${module.rds.rds_address} >> ${var.application_name}-${var.environment}.yml"
  }

  provisioner "local-exec" {
    command = "echo WEBSITE_NAME: ${var.website_name} >> ${var.application_name}-${var.environment}.yml"
  }

  provisioner "local-exec" {
    command = "echo DB_NAME: ${module.rds.db_name} >> ${var.application_name}-${var.environment}.yml"
  }

  provisioner "local-exec" {
    command = "echo DB_USERNAME: ${module.rds.username} >> ${var.application_name}-${var.environment}.yml"
  }

  provisioner "local-exec" {
    command = "echo DB_PASSWORD: ${var.rds_password} >> ${var.application_name}-${var.environment}.yml"
  }

  provisioner "local-exec" {
    command = "ansible-playbook ../ansible/site.yml -e@${var.application_name}-${var.environment}.yml --private-key=${var.private_key_path} -u ${var.ec2_user} -v"

    environment {
      ANSIBLE_HOST_KEY_CHECKING = "false"
      ANSIBLE_CONFIG            = "${var.ansible_cfg}"
    }
  }
}
