#########instance in vpc2############33
variable "vpc2_pub_subnet" {}
variable "vpc2_sg_name" {}
variable "vpc2_name" {}
variable "vpc2_server_name" {}
variable "environment_tag" {}
variable "instance_type" {}
variable "ami_name" {}
variable "keypair_name" {}
variable "public_key_path" {}


resource "aws_security_group" "vpc2_sg_22" {
    name                = var.vpc2_sg_name
    vpc_id              = var.vpc2_name
    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["10.10.0.0/16"]
    }

    egress  {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = {
        Environment     = var.environment_tag
        Name            = var.vpc2_sg_name
    }
  
}

resource "aws_key_pair" "ec2key" {
    key_name            = var.keypair_name
    public_key          = file(var.public_key_path)
}

resource "aws_instance" "private_server" {
    ami                     = var.ami_name
    instance_type           = var.instance_type
    subnet_id               = var.vpc2_pub_subnet
    vpc_security_group_ids  = [aws_security_group.vpc2_sg_22.id]
    key_name                = aws_key_pair.ec2key.key_name

    tags = {
        Environment         = var.environment_tag
        Name                = var.vpc2_server_name
    }

}