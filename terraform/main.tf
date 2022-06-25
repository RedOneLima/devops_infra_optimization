resource "aws_instance" "ubuntu" {
  ami           = "ami-052efd3df9dad4825"
  count	= 3
  instance_type = "t2.medium"
  key_name      = "${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids = [aws_security_group.ab_sg.id]
  subnet_id="subnet-0ca3b7994c3ca3831"
  tags = {
    Name        = "terraform_instance"
  }
}

output "myEC2IP" { 
  value = "${aws_instance.ubuntu.*.public_ip}"
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

resource "aws_security_group" "ab_sg" {
  name        = "allow_ssh2"
  vpc_id      = "vpc-056bd3280605a4938"
  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

 egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress { 
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["172.31.0.0/16"]
}


  tags = {
    Name = "allow_ssh"
  }
}

