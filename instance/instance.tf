#variables#
variable "environment_tag" {}
variable "sg_bastion" {}
variable "keypair_name" {}
variable "ami_name" {}
variable "instance_type" {}
variable "public_key_path" {}
variable "vpc_name" {}
variable "subnet_public" {}
variable "sg_app_name" {}
variable "app_server_name" {}
variable "subnet_app" {}
variable "bastion_name" {}
variable "provider_alias" {}


######
# module "vpc" {
#     source      = "../network"
# }

resource "aws_key_pair" "ec2key" {
    key_name            = var.keypair_name
    public_key          = file(var.public_key_path)
}

########bastion setup##########

resource "aws_security_group" "sg_22" {
    name                = var.sg_bastion
    vpc_id              = var.vpc_name
    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["146.196.35.122/32"]
    }

    egress  {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    tags = {
        Environment     = var.environment_tag
        Name            = var.sg_bastion
    }
  
}



resource "aws_instance" "testpublicinstance" {
    ami                     = var.ami_name
    instance_type           = var.instance_type
    subnet_id               = var.subnet_public
    vpc_security_group_ids  = [aws_security_group.sg_22.id]
    key_name                = aws_key_pair.ec2key.key_name

    tags = {
        Environment         = var.environment_tag
        Name                = var.bastion_name
    }
}

########## app-server################
resource "aws_security_group" "sg_app" {
    # Name                    = var.sg_app_name
    vpc_id                  = var.vpc_name
    ingress {
        from_port           = 22
        to_port             = 22
        protocol            = "tcp"
        cidr_blocks         = ["10.10.1.0/24"]
    }
    # ingress {
    #     from_port           = 0
    #     to_port             = 0
    #     protocol            = "icmp"
    #     cidr_blocks         = ["0.0.0.0/0"]
    # }

    egress {
        from_port           = 0
        to_port             = 0
        protocol            = "-1"
        cidr_blocks         = ["0.0.0.0/0"]
    }

    tags = {
        Environment         = var.environment_tag
        Name                = var.sg_app_name
    }

}

resource "aws_instance" "private_server" {
    ami                     = var.ami_name
    instance_type           = var.instance_type
    subnet_id               = var.subnet_app
    vpc_security_group_ids  = [aws_security_group.sg_app.id]
    key_name                = aws_key_pair.ec2key.key_name

    tags = {
        Environment         = var.environment_tag
        Name                = var.app_server_name
    }

}


