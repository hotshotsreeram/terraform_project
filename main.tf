provider "aws" {
  region  = var.aws_region
}

resource "aws_vpc" "project_vpc" {
  cidr_block = var.custom_vpc

  tags = {
    Name = var.vpc_tags
  }
}

resource "aws_subnet" "project_public_subnet" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = var.public_subnet
  availability_zone = var.aws_zone

  tags = {
    Name = var.public_subnet_tags
  }
}

resource "aws_subnet" "project_private_subnet" {
  vpc_id            = aws_vpc.project_vpc.id
  cidr_block        = var.private_subnet
  availability_zone = var.aws_zone

  tags = {
    Name = var.private_subnet_tags
  }
}

resource "aws_internet_gateway" "project_ig" {
  vpc_id = aws_vpc.project_vpc.id

  tags = {
    Name = var.internet_gateway_tags
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.project_vpc.id

  route {
    cidr_block = var.route_table
    gateway_id = aws_internet_gateway.project_ig.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.project_ig.id
  }

  tags = {
    Name = var.route_table_tags
  }
}

resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.project_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "web_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.project_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.route_table]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.route_table]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.route_table]
  }
}

resource "aws_instance" "web_instance" {
  ami           = var.ami
  instance_type = var.type
  key_name      = var.key

  subnet_id                   = aws_subnet.project_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
  #!/bin/bash -ex
  
  sudo apt-get update
  sudo apt install nginx -y
  echo "<h1>$(curl https://api.prod.rest/?format=text)</h1>" >  /usr/share/nginx/html/index.html 
  systemctl enable nginx
  systemctl start nginx
  EOF

  tags = {
    "Name" : var.vm_tags
  }
}