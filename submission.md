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

---

**__NOTE__**: Due to the requirements of kubeadm, the stated t2.micro and t3.micro do not have enough resourses to satifiy minimum system requirements. Therefore, t2.medium is being used. 

---


```bash
cat main.tf

resource "aws_instance" "ubuntu" {
  ami           = "ami-052efd3df9dad4825"
  instance_type = "t2.medium"
  key_name      = "${aws_key_pair.generated_key.key_name}"
  tags = {
    Name        = "terraform_instance"
  }
}

output "myEC2IP" {
  value = "${aws_instance.ubuntu.public_ip}"
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "mykey2"
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

kylehewittngc@ip-172-31-28-155:~/capstone$ terraform apply

...

aws_instance.rhel: Creation complete after 42s [id=i-0c95e1e36e5107a67]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

Outputs:

myEC2IP = "54.83.74.19"

```

We can test this by ssh to the new EC2 instance (make sure to change the permission of the key)

```bash
kylehewittngc@ip-172-31-28-155:~/capstone$ chmod 600 myKey.pem
kylehewittngc@ip-172-31-28-155:~/capstone$ ssh -i myKey.pem ubuntu@54.83.74.19
[ec2-user@ip-172-31-87-55 ~]$ whoami && hostname
ec2-user
ip-172-31-87-55.ec2.internal
```

We can check the status from the AWS console 

![image](https://user-images.githubusercontent.com/22536759/175610219-c2f12df6-405f-4387-bc03-bbbbce182e31.png)

Now we will scale up by adding these 2 lines to `main.tf`

```bash
kylehewittngc@ip-172-31-28-155:~/capstone$ diff main.tf

  ami           = "ami-052efd3df9dad4825"
+ count = 3
  instance_type = "t2.medium"

...

  output "myEC2IP" {
- value = "${aws_instance.ubuntu.public_ip}" 
+ value = "${aws_instance.ubuntu.*.public_ip}"
}
```

Now run apply to get the additional instances

```bash
kylehewittngc@ip-172-31-28-155:~/capstone$ terraform apply
```

![image](https://user-images.githubusercontent.com/22536759/175614543-4be90e94-2c72-43f8-aee1-a62628aab940.png)

## Install and Configure Kubernetes

All the needed steps to install kubeadm and start our control plane (master) nodes are in the script `install_k8s.sh`

```bash
kylehewittngc@ip-172-31-28-155:~/capstone$ cat install_k8s.sh

#!/bin/bash
swapoff -a
curl -fsSL https://get.docker.com -o get-docker.sh
DRY_RUN=1 sudo sh ./get-docker.sh
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-cache madison kubeadm
sudo apt-get install -y kubelet=1.23.6-00 kubeadm=1.23.6-00 kubectl=1.23.6-00
sudo hostnamectl set-hostname master.example.com
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

sudo kubeadm init
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes
```

Copy to master node

```bash
kylehewittngc@ip-172-31-28-155:~/capstone$ chmod +x install_k8s.sh
kylehewittngc@ip-172-31-28-155:~/capstone$ scp -p -i myKey.pem install_k8s.sh 
ubuntu@54.226.15.188:/home/ubuntu
install_k8s.sh                                                                                                                                                   100% 1106     2.2MB/s   00:00
```

Execute the script on the remote system

```bash
kylehewittngc@ip-172-31-28-155:~/capstone$ ssh -i myKey.pem ubuntu@54.226.15.188 "./install_k8s.sh"

...

kubeadm join 172.31.16.119:6443 --token e8w6ko.4q91edczl30a6ar5 \
        --discovery-token-ca-cert-hash sha256:1d7f217f7c8dc989b8328546559959298e959584d4fab71828c578b90533abdb
NAME                 STATUS     ROLES                  AGE   VERSION
master.example.com   NotReady   control-plane,master   3s    v1.23.6

```

Now we must set up our worker nodes
First we must allow TCP traffic within subnet

Within `EC2 > Security Groups > sg-0a5402b40de29840d - allow_ssh2 > Edit inbound rules`

![image](https://user-images.githubusercontent.com/22536759/175665221-01f8192c-67fe-444c-84ed-78841ac4a616.png)


```bash
kylehewittngc@ip-172-31-28-155:~/capstone$ scp -p -i myKey.pem node.sh ubuntu@34.203.223.52:~
node.sh                                                 100%  944     1.9MB/s   00:00                                                                                           

kylehewittngc@ip-172-31-28-155:~/capstone$ ssh -t -i myKey.pem ubuntu@34.203.223.52 "./node.sh"

...

kylehewittngc@ip-172-31-28-155:~/capstone$ ssh -t -i myKey.pem ubuntu@34.203.223.52 "sudo kubeadm join 172.31.16.119:6443 --token e8w6ko.4q91edczl30a6ar5 --discovery-token-ca-cert-hash sha256:1d7f217f7c8dc989b8328546559959298e959584d4fab71828c578b90533abdb"

...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

```

```bash

kylehewittngc@ip-172-31-28-155:~/capstone$ scp -p -i myKey.pem node.sh ubuntu@54.167.63.97:~
node.sh                                                 100%  944     1.9MB/s   00:00                                                                                           

kylehewittngc@ip-172-31-28-155:~/capstone$ ssh -t -i myKey.pem ubuntu@54.167.63.97 "./node.sh"

...

kylehewittngc@ip-172-31-28-155:~/capstone$ ssh -t -i myKey.pem ubuntu@54.167.63.97 "sudo kubeadm join 172.31.16.119:6443 --token e8w6ko.4q91edczl30a6ar5 --discovery-token-ca-cert-hash sha256:1d7f217f7c8dc989b8328546559959298e959584d4fab71828c578b90533abdb"

...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.

```

```bash
kylehewittngc@ip-172-31-28-155:~/capstone$ ssh -i myKey.pem ubuntu@54.226.15.188 "kubectl get nodes"                                                                                                 NAME                 STATUS     ROLES                  AGE     VERSION
master.example.com   NotReady   control-plane,master   110m    v1.23.6
node1.example.com    NotReady   <none>                 8m32s   v1.23.6
node2.example.com    NotReady   <none>                 74s     v1.23.6

```

```bash
  "54.226.15.188" -> mater.example.com -> 172.31.16.119
  "54.167.63.97" -> node1 -> 172.31.20.65
  "34.203.223.52" -> node2 -> 172.31.28.7
```
