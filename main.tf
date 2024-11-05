provider "aws" {
}


variable "subnet_cidr" {
  type        = string
  default     = ""
  description = "cidr for subnet "
}


resource "aws_vpc" "test-vpc" {
    cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "test-subnet" {
    vpc_id = aws_vpc.test-vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-south-1a"
}

output "testvpc-id" {
    value = aws_vpc.test-vpc.id

}

output "testvpc-arn" {
    value = aws_vpc.test-vpc.arn
}