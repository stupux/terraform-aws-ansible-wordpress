

## Requirements:

- Terraform
- Ansible
- AWS

The purpose is to automate the creation of the infrastructure and the setup of the latest wordpress application, creating a fully operational AWS VPC network (subnets, routing tables, igw, etc), it will also create everything that need to be for creating EC2 and RDS instances (security key, security group, subnet group).

It will also create the Elastic Load Balancer and add the EC2 instance(s) automatically that were created using ansible playbook.


### Resources

- Create a VPC with 4x VPC subnets (2x public and 2x private) in different AZ zones inside the AWS region
- Create a ssh specific security group only acesible from ec2 instances and not from public load balancing dns address ```22```
- Create ```var.instance_count``` security group(s) for web ```80, 443```
- Create one specific security group for rds ```3306``` (not  public internet facing, only from vpc)
- Create one specific security group for load balancer on port ```80```
- Provision ec2 instances with default ```ubuntu 14.04 LTS``` ami in 2 different public AZ
- Provision 1x RDS instance in private subnets
- Launch and configure public facing VPC ELB (cross_az_load_balancing) and attach VPC subnets
- Register EC2 instances on ELB

#### Tools used

```shell
ansible --version
ansible 2.3.2.0
```
```
terraform version
Terraform v0.11.5
```

Before using the terraform, we need to export `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` as environment variables:

```
export AWS_ACCESS_KEY_ID="xxxxxxxxxxxxxxxx"
export AWS_SECRET_ACCESS_KEY="yyyyyyyyyyyyyyyyyyyy"
```

or use it with [AWS CLI configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html).

### 1. Infrastructure

##### Plan
Initialize terraform:
```cd terraform-aws```
```terraform init```

Check config variables at 
```terraform-aws/variables.yml```

To generate and show an execution plan (dry run):
```terraform plan```

You can select one of ubuntu images from [Ubuntu Amazon EC2 AMI Locator](https://cloud-images.ubuntu.com/locator/ec2/), based on your aws region and edit in ```terraform-aws/variables.yml```

##### Deploy
To build or makes actual changes in infrastructure:
```terraform apply```

To inspect Terraform state or plan:
```terraform show```

To destroy Terraform-managed infrastructure:
```terraform destroy```

**Note**: Terraform stores the state of the managed infrastructure from the last time Terraform was run. 
Terraform uses the state to create plans and make changes to the infrastructure.

### 2. Application

Once the Terraform create all the resources over AWS, it will use ansible to install the wordpress over the EC2 instance(s).

#### Playbook

##### nginx.yml

1. Install the nginx repository 
2. Update repositories 
3. Install latest nginx
4. Write the modified nginx.conf
5. Delete the default unnecessary files

##### php5.yml
1. Install and update php5 repository 
2. Install PHP5-FPM with modules 
    - php5-fpm
    - php5-cgi
    - php5-cli
    - php5-curl
    - php5-json
    - php5-odbc
    - php5-tidy
    - php5-common
    - php5-xmlrpc
    - php5-gd
    - php-pear
    - php5-dev
    - php5-imap
    - php5-mcrypt
    - php5-mysqlnd
3. Copy the custom settings from ```templates``` folder
4. Restart

##### deploy.yml
1. Delete the html directory
2. Check if wordpress directory exists
3. Create wordpress directory ```website_name```
4. Download and unzip ```latest``` wordpress 
5. Rename the extracted wordpress directory as ```website_name```
6. Copy the wp-config.php file inside the ```website_name``` directory with ```terraform-aws/variables.yml``` 
7. Reset the permission on ```website_name``` directory
8. Add the ```website_name``` config
9. Enable ```website_name``` site config

#### templates
- nginx.conf.j2
- php.ini.j2
- virtualhost.conf.j2
- wp-config.php.j2
- www.conf.j2



#### Test Ansible
```ansible-playbook site.yml -e@../terraform-aws/my-app-development.yml --private-key=~/.ssh/private.pem -u ubuntu -v```

`{application_name}-{environment}.yml` will be generated automatically when terraform is finished, containing the dns name of the RDS database 

**Note:** `terraform.py` is dynamic inventory created by [CiscoCloud](https://github.com/CiscoCloud/terraform.py)