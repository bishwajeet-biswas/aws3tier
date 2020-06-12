provider "aws" {
  alias                   = "north"
  region                  = "us-east-1"
  shared_credentials_file = "~/.aws/creds"
  profile                 = "jeet-terraform"
}

provider "aws" {
  alias                   = "ohio"
  region                  = "us-east-2"
  shared_credentials_file = "~/.aws/creds"
  profile                 = "jeet-terraform"
}

module "vpc" {
  source            = "./network"
  providers = {
    aws   = aws.north
  }
  vpc_name          = "vpc-terraform"
  cidr_vpc          = "10.10.0.0/16"
  environment_tag   = "terraform"
  cidr_pub          = "10.10.1.0/24"
  az                = "us-east-1a"
  az_app1           = "us-east-1a"
  az_app2           = "us-east-1b"
  az_db1            = "us-east-1a"
  az_db2            = "us-east-1b"
  cidr_app1         = "10.10.2.0/24"
  cidr_app2         = "10.10.3.0/24"
  cidr_db1          = "10.10.4.0/24"
  cidr_db2          = "10.10.5.0/24"
  igw_name          = "testigw"
  peering_id        = module.peering.peering_id
}

module "instance" {
  source            = "./instance"
  providers = {
  aws               = aws.north
  }
  provider_alias    = "north-virginia"
  vpc_name          = module.vpc.vpc_id_created
  subnet_public         = module.vpc.public_subnet_id_created
  subnet_app        = module.vpc.app_subnet1_id_created
  environment_tag   = "terraform"
  sg_bastion        = "ssh-sg"
  sg_app_name       = "app-sg"
  bastion_name      = "bastion-server"
  app_server_name   = "app-server"
  keypair_name      = "ec2-pair"
  ami_name          = "ami-085925f297f89fce1"
  instance_type     = "t2.micro"
  public_key_path   = "~/.ssh/id_rsa_jeet.pub"

}



############# vpc2 #########################3
module "vpc2" {
  source              = "./vpc2"
  providers = {
    aws = aws.ohio
  }
  vpc_name            = "vpc-terraform-peering"
  cidr_vpc            = "10.20.0.0/16"
  environment_tag     = "terraform-vpc-peering"
  cidr_pub            = "10.20.1.0/24"
  az                  = "us-east-2a"
  igw_name            = "igwpeering"
  peering_id          = module.peering.peering_id

}



############# peering####################

module  "peering" {
  source               = "./peering"
  providers = {
    aws   = aws.north
  }
  accepter_vpc_id      = module.vpc2.vpc2_id_created
  requester_vpc_id     = module.vpc.vpc_id_created
  # owner_id             = "259114773877"
  accepter_region      = "us-east-2"
  
  # requester_region    = "northvirginia"
  
}
###instance in vpc2---


module "instance_vpc2" {
  source            = "./instance_vpc2"
  providers = {
    aws             = aws.ohio
  }
  vpc2_pub_subnet   = module.vpc2.public_subnet_created
  vpc2_sg_name      = "vpc2_pub_sg"
  vpc2_name         = module.vpc2.vpc2_id_created
  vpc2_server_name  = "test-peering"
  environment_tag   = "terraform"
  keypair_name      = "ec2-pair"
  ami_name          = "ami-07c1207a9d40bc3bd"
  instance_type     = "t2.micro"
  public_key_path   = "~/.ssh/id_rsa_jeet.pub"
}