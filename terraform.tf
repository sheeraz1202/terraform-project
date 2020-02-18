# Commission and decommission the infrastructure with just one command.
# This script buils a VPC with 4 subnets ie 1Public and 1Private each in 2 different availability zone.
# Route table and association and internet to the public routing is also done.
# A security group is also created allowing ssh, http and https.
# Creates 2 instances webserver1 and webserver2 in public subnets in both the availability zone. User data has been passed from files (install_httpd1 and install_httpd2) to install http and display a message on the url.
# A classic ELB is also created to load balance the request. A bucket should be already created in our account with public access or a instance role should be created to have permission to communicate with S3 service.
# The ElB URL can be mapped with route53 to serve requests from (www.example.com) - This has not been done in this script as i have purchased any domain.

provider "aws"{
  region     = "us-east-1"
}

# Creating a VPC
resource "aws_vpc" "newvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "newvpc"
  }
}

# Creating internet gateway
resource "aws_internet_gateway" "newvpc-igw" {
  vpc_id = "${aws_vpc.newvpc.id}"

  tags = {
    Name = "newvpc-igw"
  }
}

# Creating public subnet in us-east-1a
resource "aws_subnet" "public-subnet-1" {
  vpc_id     = "${aws_vpc.newvpc.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet-1"
  }
}

# Creating private subnet in us-east-1b
resource "aws_subnet" "private-subnet-1" {
  vpc_id     = "${aws_vpc.newvpc.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet-1"
  }
}
# Creating public subnet in us-east-1b
resource "aws_subnet" "public-subnet-2" {
  vpc_id     = "${aws_vpc.newvpc.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "public-subnet-2"
  }
}

# Creating private subnet in us-east-1b
resource "aws_subnet" "private-subnet-2" {
  vpc_id     = "${aws_vpc.newvpc.id}"
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-2"
  }
}

# Creating public route table
resource "aws_route_table" "pub-rt" {
  vpc_id = "${aws_vpc.newvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.newvpc-igw.id}"
  }
}

# Creating private route table
resource "aws_route_table" "pri-rt" {
  vpc_id = "${aws_vpc.newvpc.id}"
}

# Creating public route table association
resource "aws_route_table_association" "pub-association1" {
  subnet_id      = "${aws_subnet.public-subnet-1.id}"
  route_table_id = "${aws_route_table.pub-rt.id}"
}

# Creating private route table association
resource "aws_route_table_association" "pri-association1" {
  subnet_id      = "${aws_subnet.private-subnet-1.id}"
  route_table_id = "${aws_route_table.pri-rt.id}"
}

# Creating public route table association
resource "aws_route_table_association" "pub-association2" {
  subnet_id      = "${aws_subnet.public-subnet-2.id}"
  route_table_id = "${aws_route_table.pub-rt.id}"
}

# Creating private route table association
resource "aws_route_table_association" "pri-association2" {
  subnet_id      = "${aws_subnet.private-subnet-2.id}"
  route_table_id = "${aws_route_table.pri-rt.id}"
}



# Creating secutity groups
resource "aws_security_group" "web" {
  name        = "web"
  description = "HTTP, HTTPs and SSH allowed"
  vpc_id      = "${aws_vpc.newvpc.id}"

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

#Creating instance in public subnet
resource "aws_instance" "webserver1" {
  ami           = "ami-00eb20669e0990cb4" # us-east-1
  availability_zone = "us-east-1a"
  instance_type = "t2.micro"
  key_name = "office"
  subnet_id      = "${aws_subnet.public-subnet-1.id}"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  associate_public_ip_address = true
  user_data = "${file("install_httpd1.sh")}"
  credit_specification {
    cpu_credits = "unlimited"
  }
  tags = {
    Name = "webserver1"
  }
}
#Creating instance in public subnet
resource "aws_instance" "webserver2" {
  ami           = "ami-00eb20669e0990cb4" # us-east-1
  availability_zone = "us-east-1b"
  instance_type = "t2.micro"
  key_name = "office"
  subnet_id      = "${aws_subnet.public-subnet-2.id}"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  associate_public_ip_address = true
  user_data = "${file("install_httpd2.sh")}"
  credit_specification {
    cpu_credits = "unlimited"
  }
  tags = {
    Name = "webserver2"
  }
}

#Creating a load balancer for public subnets
resource "aws_elb" "elb-terraform" {
  name               = "elb-terraform"

  access_logs {
    bucket        = "elb-logs-852"
    interval      = 60
  }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }


  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  security_groups    = ["${aws_security_group.web.id}"]
  subnets = ["${aws_subnet.public-subnet-1.id}", "${aws_subnet.public-subnet-2.id}"]
  instances                   = ["${aws_instance.webserver1.id}", "${aws_instance.webserver2.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "elb-terraform"
  }
}
