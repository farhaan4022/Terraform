provider "aws" {
    region = "ap-south-1"
}


variable "vpc_cider_block" {}
variable "subnet_cider_block" {}
variable "availability_zone" {}
variable "env-prefix" {}
variable  "my_ip"{}
variable "instance_type" {}
variable "public_key_path" {}


resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cider_block
    tags = {
       Name : "${var.env-prefix}-vpc"
    }
}

resource "aws_subnet" "myapp-subnet" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cider_block
    availability_zone = var.availability_zone
    tags = {
        Name : "${var.env-prefix}-subnet"
    }
}

resource "aws_route_table" "myapp-route_table" {
    vpc_id = aws_vpc.myapp-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-internet_gateway.id
    }
    tags = {
        Name : "${var.env-prefix}-routetable"
    }
}

resource "aws_internet_gateway" "myapp-internet_gateway" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name : "${var.env-prefix}-internet_gateway"
    }
}

resource "aws_route_table_association" "as-rtb-subnet" {
    subnet_id = aws_subnet.myapp-subnet.id
    route_table_id = aws_route_table.myapp-route_table.id 

}

#resource "aws_security_group" "my_app-sg"  for new sg
resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port = 22 #range
        to_port = 22
        protocol = "TCP"
        cidr_blocks = [var.my_ip]
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1" #any
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }

    tags = {
        Name : "${var.env-prefix}-def_security_group"
    }


}

data "aws_ami" "latest-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-kernel-*-x86_64-gp2"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

output "aws_linux_image_id" {
    value = data.aws_ami.latest-linux-image.id
}


resource "aws_key_pair" "ssh-key" {
    key_name = "access_key"
    public_key = file(var.public_key_path)
}

resource "aws_instance" "myapp-server" {
    ami = data.aws_ami.latest-linux-image.id
    instance_type = var.instance_type
    subnet_id = aws_subnet.myapp-subnet.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]
    availability_zone = var.availability_zone
    associate_public_ip_address = true #for ip address
    key_name = aws_key_pair.ssh-key.key_name


    user_data = file("script.sh")
    user_data_replace_on_change = true


    tags = {
        Name : "${var.env-prefix}-myapp"
    }

}

output "ec2-public-ip" {
    value = aws_instance.myapp-server.public_ip
}

