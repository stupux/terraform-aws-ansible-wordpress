

## Requirements:

- Terraform
- Ansible
- AWS

The purpose is to create a fully operational AWS VPC infrastructure (subnets, routing tables, igw, etc), it will also create everything that need to be for creating EC2 and RDS instances (security key, security group, subnet group).

It will also create the Elastic Load Balancer and add the EC2 instance(s) automatically that were created using this playbook.


### Tasks

- Create 1 x VPC with 4 x VPC subnets(2 x public and 2 x private) in differrent AZ zones inside the AWS region
- Create 1 x security group for each(ssh, web, rds and elb)
- Provision ec2 instances with default ubuntu 14.04 LTS ami in 2 different public AZ
- Provision 1 x RDS instance in private subnets
- Launch and configure public facing VPC ELB (cross_az_load_balancing) and attach VPC subnets
- Register EC2 instances on ELB


### Tools Used:
```shell
ansible --version
ansible 2.3.2.0

terraform version
Terraform v0.11.5
```

Before using the terraform, we need to export `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as environment variables:

```
export AWS_ACCESS_KEY_ID="xxxxxxxxxxxxxxxx"
export AWS_SECRET_ACCESS_KEY="yyyyyyyyyyyyyyyyyyyy"
```

### 1. Infrastructure

Initialize terraform:
```cd terraform-aws```
```terraform init```

Update config file at 
```terraform-aws/variables.yml```

To generate and show an execution plan (dry run):
```terraform plan```

To build or makes actual changes in infrastructure:
```terraform apply```

To inspect Terraform state or plan:
```terraform show```

To destroy Terraform-managed infrastructure:
```terraform destroy```

**Note**: Terraform stores the state of the managed infrastructure from the last time Terraform was run. Terraform uses the state to create plans and make changes to the infrastructure.

### 2. Application

Once the Terraform create all the resources over AWS, it will use ansible to install the wordpress over the EC2 instance(s)

#### Test Ansible
```ansible-playbook site.yml -e@../terraform-aws/my-app-development.yml --private-key=~/.ssh/private.pem -u ubuntu -v```

`{application_name}-{environment}.yml` will be generated automatically when terraform is finished, containing the dns name of the RDS database 

**Note:** `terraform.py` is dynamic inventory created by [CiscoCloud](https://github.com/CiscoCloud/terraform.py)

