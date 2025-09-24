////////////////////// NETWORKING

resource "aws_vpc" "main_vpc" {

  cidr_block = var.cidrs["vpc"]

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}-vpc"
    }
  )
}

resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.cidrs["subnet"]

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}-subnet"
    }
  )
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}-igw"
    }
  )
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = var.cidrs["internet"]
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}-routetable"
    }
  )
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_security_group" "main_sg" {
  name   = "Allow_SSH_HTTP"
  vpc_id = aws_vpc.main_vpc.id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}-main_sg"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ingress_ssh" {
  security_group_id = aws_security_group.main_sg.id
  cidr_ipv4         = var.cidrs["internet"]
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22

  lifecycle {
    replace_triggered_by = [ aws_security_group.main_sg.id ]
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}-ingress_ssh"
    }
  )
}

resource "aws_vpc_security_group_ingress_rule" "ingress_http" {
  security_group_id = aws_security_group.main_sg.id
  cidr_ipv4         = var.cidrs["internet"]
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80

  lifecycle {
    replace_triggered_by = [ aws_security_group.main_sg.id ]
  }
  
  tags = merge(
    local.tags,
    {
      Name = "${var.environment}-ingress_http"
    }
  )
}

resource "aws_vpc_security_group_egress_rule" "egress_all" {
  security_group_id = aws_security_group.main_sg.id
  cidr_ipv4         = var.cidrs["internet"]
  ip_protocol       = "-1"

  lifecycle {
    replace_triggered_by = [ aws_security_group.main_sg.id ]
  }

  tags = merge(
    local.tags,
    {
      Name = "${var.environment}-egress_all"
    }
  )
}



# ////////////////////// EC2

resource "aws_key_pair" "key_pair_linux" {
  key_name   = "aws_devops_key"
  public_key = file(var.key_pair)

    tags = merge(
    local.tags,
    {
      Name = "${var.environment}-keypair"
    }
  )
}

data "aws_ami" "amazon_linux2023" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}



resource "aws_instance" "ec2_linux" {
  ami                    = data.aws_ami.amazon_linux2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main_subnet.id
  vpc_security_group_ids = [aws_security_group.main_sg.id]
  key_name               = aws_key_pair.key_pair_linux.key_name

  user_data                   = var.nginx_script
  user_data_replace_on_change = true

      tags = merge(
    local.tags,
    {
      Name = "${var.environment}-ec2_linux"
    }
  )
}

resource "aws_eip" "pub_ip" {
  instance = aws_instance.ec2_linux.id

      tags = merge(
    local.tags,
    {
      Name = "${var.environment}-eip"
    }
  )
}