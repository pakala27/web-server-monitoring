provider "aws" {
  region = "eu-central-1"
}

#Variable Definition
variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     =  "192.168.0.0/16"
}
variable "sn1_cidr" {
  description = "subnet 1 CIDR block"
  default     =  "192.168.1.0/24"
}

#VPC Creation
resource "aws_vpc" "vpc-web-01" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "vpc-web-01"
  }
}

# Subnets creation
resource "aws_subnet" "sn-web-01" {
  vpc_id            = aws_vpc.vpc-web-01.id
  cidr_block        = var.sn1_cidr
  availability_zone = "eu-central-1a"

  tags = {
    Name = "sn-web-01"
  }
}


#Internet Gateway
resource "aws_internet_gateway" "igw-web-01" {
  vpc_id = aws_vpc.vpc-web-01.id

  tags = {
    Name = "igw-web-01"
  }
}

#Route Table
resource "aws_route_table" "rtb-web-01" {
  vpc_id = aws_vpc.vpc-web-01.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw-web-01.id
  }

  tags = {
    Name = "rtb-web-01"
  }
}

#Route table association for subnet 1
resource "aws_route_table_association" "rtb-web-assc-01" {
  subnet_id      = aws_subnet.sn-web-01.id
  route_table_id = aws_route_table.rtb-web-01.id
}

#Security Group
resource "aws_security_group" "sgweb01" {
  name        = "allow_tcp"
  description = "allow all ports within VPC and allow SSH from anywhere"
  vpc_id      = aws_vpc.vpc-web-01.id

  ingress {
      description      = "All TCP ports allowed inside VPC"
      from_port        = 0
      to_port          = 65535
      protocol         = "tcp"
      cidr_blocks      = [aws_vpc.vpc-web-01.cidr_block]
    }
  ingress {
      description      = "SSH access to All Instance"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
      description      = "http access to Web server Instance"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
      description      = "Promethes port access to Monitoring Instance"
      from_port        = 9090
      to_port          = 9090
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
      description      = "Grafana port access to Monitoring Instance"
      from_port        = 3000
      to_port          = 3000
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sq-web-01"
  }
}

#Create network interface and assign a private IP from subnet 1 for web instance
resource "aws_network_interface" "ni-web-01" {
  subnet_id       = aws_subnet.sn-web-01.id
  private_ips     = ["192.168.1.10"]
  security_groups = [aws_security_group.sgweb01.id]
}

#Assign Elastic IP to the network interface created on previous step for web instance
resource "aws_eip" "eip-web-01" {
  vpc                       = true
  network_interface         = aws_network_interface.ni-web-01.id
  associate_with_private_ip = "192.168.1.10"
  depends_on                = [aws_internet_gateway.igw-web-01]
  tags = {
    Name = "eip-web-01"
  }
}

#Create network interface and assign a private IP from subnet 1 for DevOps instance
resource "aws_network_interface" "ni-devops-01" {
  subnet_id       = aws_subnet.sn-web-01.id
  private_ips     = ["192.168.1.20"]
  security_groups = [aws_security_group.sgweb01.id]
}

#Assign Elastic IP to the network interface created on previous step for DevOps instance
resource "aws_eip" "eip-devops-01" {
  vpc                       = true
  network_interface         = aws_network_interface.ni-devops-01.id
  associate_with_private_ip = "192.168.1.20"
  depends_on                = [aws_internet_gateway.igw-web-01]
  tags = {
    Name = "eip-devops-01"
  }
}

#Create network interface and assign a private IP from subnet 1 for monitoring instance
resource "aws_network_interface" "ni-monitoring-01" {
  subnet_id       = aws_subnet.sn-web-01.id
  private_ips     = ["192.168.1.30"]
  security_groups = [aws_security_group.sgweb01.id]
}

#Assign Elastic IP to the network interface created on previous step
resource "aws_eip" "eip-monitoring-01" {
  vpc                       = true
  network_interface         = aws_network_interface.ni-monitoring-01.id
  associate_with_private_ip = "192.168.1.30"
  depends_on                = [aws_internet_gateway.igw-web-01]
  tags = {
    Name = "eip-monitoring-01"
  }
}


#Create DevOps EC2 Instance
resource "aws_instance" "devops" {
  ami               = "ami-06ec8443c2a35b0ba"
  instance_type     = "t2.micro"
  availability_zone = "eu-central-1a"
  key_name          = "web-vpc-keypair"
  network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.ni-devops-01.id
  }
  user_data = <<EOF
#!/bin/bash
sudo useradd ansible
sudo su - ansible
sudo dnf install python3-pip
pip3 install ansible --user
EOF
  tags = {
    Name = "devops"
  }
}

#Create monitoring EC2 Instance
resource "aws_instance" "monitoring" {
  ami               = "ami-06ec8443c2a35b0ba"
  instance_type     = "t2.micro"
  availability_zone = "eu-central-1a"
  key_name          = "web-vpc-keypair"
  network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.ni-monitoring-01.id
  }
  user_data = <<EOF
#!/bin/bash
sudo useradd ansible
EOF
  tags = {
    Name = "monitoring"
  }
}

#Create web EC2 Instance
resource "aws_instance" "web" {
  ami               = "ami-06ec8443c2a35b0ba"
  instance_type     = "t2.micro"
  availability_zone = "eu-central-1a"
  key_name          = "web-vpc-keypair"
  network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.ni-web-01.id
  }
  user_data = <<EOF
#!/bin/bash
sudo yum install -y httpd
sudo echo "<h2> apache web server </h2>" > /var/www/html/index.html
sudo systemctl start httpd
sudo systemctl enable httpd
sudo useradd ansible
sudo su - ansible
EOF
  tags = {
    Name = "web"
  }
}


#Output
output "devops_public_ip" {
  value = aws_eip.eip-devops-01.public_ip
}
output "monitoring_public_ip" {
  value = aws_eip.eip-monitoring-01.public_ip
}
output "web_public_ip" {
  value = aws_eip.eip-web-01.public_ip
}