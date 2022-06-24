# DevOps Infra Optimization Submission

Starting with the course lab environement
![image](https://user-images.githubusercontent.com/22536759/175562105-7838fd9f-5ed5-4ec6-9010-64286d3ec747.png)

Log into the RDP session. This will be the Terraform controller
![image](https://user-images.githubusercontent.com/22536759/175562560-d7e70f00-9050-4677-9703-44b46d1b93f5.png)

Start the AWS Lab environement
![image](https://user-images.githubusercontent.com/22536759/175562971-ee409913-f0e0-4870-9f51-cf3808d17dbb.png)

Log into the AWS Console. We will use this to manage and monitor our resources (EC2, EKS, etc)
![image](https://user-images.githubusercontent.com/22536759/175564229-e3793962-0bd6-4160-b3ea-6634e196ce89.png)

## Create EC2 Instance using Terraform

From the RDP session:

* Verify that terraform is installed

```bash
kylehewittngc@ip-172-31-28-155:~$ terraform version

Terraform v1.1.6
on linux_amd64

Your version of Terraform is out of date! The latest version
is 1.2.3. You can update by downloading from https://www.terraform.io/downloads.html

```

Next we export our AWS Key and ID for terraform to use

```bash
export AWS_ACCESS_KEY_ID="ASIA5HT6PW3S3YP3QB4N"
export AWS_SESSION_TOKEN="FwoGZXIvYXdzEIj////////..."
export AWS_SECRET_ACCESS_KEY="*****"
```

These values were pulled from the AWS API Access tab in the lab page
![image](https://user-images.githubusercontent.com/22536759/175569226-49d1d34a-26b5-4695-823d-b2c29a4f6bf3.png)

Create aws.tf

```bash
kylehewittngc@ip-172-31-28-155:~/capstone$ cat aws.tf

provider "aws" {
  region        = "us-east-1"
}
```

initalize Terraform project

```bash
kylehewittngc@ip-172-31-28-155:~/capstone$ terraform init

Initializing the backend...

Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v4.20.0...
- Installed hashicorp/aws v4.20.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

We can verify that the terraform project initalization files are created
```bash
kylehewittngc@ip-172-31-28-155:~/capstone$ ls -a
.  ..  .terraform  .terraform.lock.hcl  aws.tf
```

Obtain VPC ID `vpc-056bd3280605a4938`

![image](https://user-images.githubusercontent.com/22536759/175606094-4e0c1aa6-d496-4d33-879b-c6ebce946897.png)



Create main.tf that will define your resources
```bash
cat main.tf

resource "aws_instance" "rhel" {
  ami           = "ami-096fda3c22c1c990a"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.generated_key.key_name}"
  tags = {
    Name        = "terraform_instance"
  }
}

output "myEC2IP" {
  value = "${aws_instance.rhel.public_ip}"
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "mykey1"
  public_key = tls_private_key.example.public_key_openssh

provisioner "local-exec" { # Create "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.example.private_key_pem}' > ./myKey.pem"
  }
}
```

Validate and deploy EC2 Instance

```bash
kylehewittngc@ip-172-31-28-155:~/capstone$ terraform plan

...

kylehewittngc@ip-172-31-28-155:~/capstone$ terraform deploy

...

aws_instance.rhel: Creation complete after 42s [id=i-0c95e1e36e5107a67]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

myEC2IP = "54.83.74.19"

```

We can test this by ssh to the new EC2 instance (make sure to change the permission of the key)

```bash
kylehewittngc@ip-172-31-28-155:~/capstone$ chmod 600 myKey.pem
kylehewittngc@ip-172-31-28-155:~/capstone$ ssh -i myKey.pem ec2-user@54.83.74.19
[ec2-user@ip-172-31-87-55 ~]$ whoami && hostname
ec2-user
ip-172-31-87-55.ec2.internal
```

We can check the status from the AWS console 

![image](https://user-images.githubusercontent.com/22536759/175610219-c2f12df6-405f-4387-bc03-bbbbce182e31.png)

