variable "region" {
  type = string
  description = "Define region"
}

variable "environment" {
  type = string
}

variable "key_pair" {
  type    = string
  description = "Provide path for a key"
}

# Provide above variables in separate file fx:
# region = "us-west-1"
# environment = "test"
# key_pair = "~/.ssh/key_path.pub"

# ----------------------------------------

variable "cidrs" {
  type = map(string)
  default = {
    vpc      = "10.0.0.0/16"
    subnet   = "10.0.0.0/24"
    internet = "0.0.0.0/0"
  }
}


variable "nginx_script" {
  type    = string
  default = <<-EOT
  #!/bin/bash
  yum update -y
  yum install -y nginx
  systemctl enable nginx
  systemctl start nginx
  EOT
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}
