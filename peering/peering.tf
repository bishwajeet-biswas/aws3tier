
#### NOTE===> if you use below module, you have to manually accept peering. 
#### NOTE====> but don't need to include providers here. 

# ####variable######
# variable "accepter_vpc_id" {}
# variable "owner_id" {}
# variable "accepter_region" {}
# variable "requester_vpc_id" {}



# resource "aws_vpc_peering_connection" "peering" {
#   peer_owner_id = var.owner_id
#   peer_vpc_id   = var.accepter_vpc_id    
#   vpc_id        = var.requester_vpc_id
#   peer_region   = var.accepter_region
# #   auto_accept   = true

#   tags = {
#     Name = "VPC Peering between north vpc and and ohio vpc"
#   }
# }

# output "peering_id" {
#     value = aws_vpc_peering_connection.peering.id
# }


##NOT====>-using below module will auto peer the vpcs. but need to include providers here. --------------------------

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

variable "accepter_vpc_id" {}
variable "accepter_region" {}
variable "requester_vpc_id" {}

data "aws_caller_identity" "ohio" {
  provider = aws.ohio
}

# Requester's side of the connection.
resource "aws_vpc_peering_connection" "ohio" {
  vpc_id        = var.requester_vpc_id
  peer_vpc_id   = var.accepter_vpc_id
  peer_owner_id = data.aws_caller_identity.ohio.account_id
  peer_region   = var.accepter_region
  auto_accept   = false

  tags = {
    Side = "Requester"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "ohio" {
  provider                  = aws.ohio
  vpc_peering_connection_id = aws_vpc_peering_connection.ohio.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

output "peering_id" {
    value = aws_vpc_peering_connection.ohio.id
}