#variables#
variable "cidr_vpc" {}
variable "vpc_name" {}
variable "environment_tag" {}
variable "az" {}
variable "cidr_pub" {}
variable "az_app1" {}
variable "az_app2" {}
variable "cidr_app1" {}
variable "cidr_app2" {}
variable "igw_name" {}
variable  "cidr_db1" {}
variable  "az_db1" {}
variable  "cidr_db2" {}
variable  "az_db2" {}
variable  "peering_id" {}
# variable "provider_alias" {}


#######

resource "aws_vpc" "vpc" {
    cidr_block              = var.cidr_vpc
    # provider_alias          = "aws.${var.provider_alias}"
    enable_dns_support      = true
    enable_dns_hostnames    = true
    tags = {
        Environment         = var.environment_tag
        Name                = var.vpc_name
    }
  
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
      Environment           = var.environment_tag
      Name                  = var.igw_name
  }
}


resource "aws_subnet" "public_ip" {
  vpc_id                    = aws_vpc.vpc.id
  cidr_block                = var.cidr_pub
  map_public_ip_on_launch   = true
  availability_zone         = var.az
  tags = {
      Environment           =var.environment_tag
      Name                  = "pubcic-subnet"
  }
}


// route table needs to be added for resources in public subnet to use the internet gateway

resource "aws_route_table" "rtb_pubcic" {
    vpc_id                  =aws_vpc.vpc.id

    route {
        cidr_block          = "0.0.0.0/0"
        gateway_id          = aws_internet_gateway.igw.id
    }

    route {
        cidr_block          = "10.20.0.0/16"
        gateway_id          = var.peering_id 
    }

    tags = {
        Environment         = var.environment_tag
        Name                = "rtb_public"
    }
  
}

// once the route table is created, this needs to associated with the public subnet to make the subnet public

resource "aws_route_table_association" "rta_public_subnet" {
  subnet_id                 = aws_subnet.public_ip.id
  route_table_id            = aws_route_table.rtb_pubcic.id
}

//eip for nat gateway

resource "aws_eip" "for_nat" {
  vpc                       = true
}

//nat gateway
resource "aws_nat_gateway" "gw" {
  allocation_id             = aws_eip.for_nat.id
  subnet_id                 = aws_subnet.public_ip.id

  tags = {
    Environment             = var.environment_tag
    Name                    = "natgw"
  }

  depends_on = [aws_internet_gateway.igw]     // this line ensures, if the subnet don't have an igw, else will give error 
}

#-----------------------app-subnet-az2---------------------------------------------------------------

resource "aws_subnet" "private_app1" {
  vpc_id                    = aws_vpc.vpc.id
  cidr_block                = var.cidr_app1
  availability_zone         = var.az_app1
  tags = {
      Environment           =var.environment_tag
      Name                  = "app-subnet1"
  }

}

###---------------app-subnet-az2----------------------------------
resource "aws_subnet" "private_app2" {
  vpc_id                    = aws_vpc.vpc.id
  cidr_block                = var.cidr_app2
  availability_zone         = var.az_app2
  tags = {
      Environment           =var.environment_tag
      Name                  = "app-subnet2"
  }

}


// creating app- route table

resource "aws_route_table" "rtb_app_az1" {
  vpc_id                    = aws_vpc.vpc.id
  route {
    cidr_block              = "0.0.0.0/0"
    gateway_id              = aws_nat_gateway.gw.id
  }

  tags = {
    Environment             = var.environment_tag
    Name                    = "app-rt-az1"
  }
}
// this will associate app-route table with app-subnet

resource "aws_route_table_association" "rtb_app_subnet_az1" {
  subnet_id                 = aws_subnet.private_app1.id
  route_table_id            = aws_route_table.rtb_app_az1.id
}

// second app subnet in deff az.. 

resource "aws_route_table" "rtb_app_az2" {
  vpc_id                    = aws_vpc.vpc.id
  route {
    cidr_block              = "0.0.0.0/0"
    gateway_id              = aws_nat_gateway.gw.id
  }

  tags = {
    Environment             = var.environment_tag
    Name                    = "app-rt-az2"
  }
}

resource "aws_route_table_association" "rtb_app_subnet_az2" {
  subnet_id                 = aws_subnet.private_app2.id
  route_table_id            = aws_route_table.rtb_app_az2.id
}

####-------------------------database subnets--------------------
// first db subnet in az 1

resource "aws_subnet" "db_subnet1" {
  vpc_id                    = aws_vpc.vpc.id
  cidr_block                = var.cidr_db1
  availability_zone         = var.az_db1
  tags = {
      Environment           =var.environment_tag
      Name                  = "db_subnet1"
  }

}


resource "aws_route_table" "db_rt1" {
  vpc_id                    = aws_vpc.vpc.id
  route {
    cidr_block              = "0.0.0.0/0"
    gateway_id              = aws_nat_gateway.gw.id
  }

  tags = {
    Environment             = var.environment_tag
    Name                    = "rt-db1"
  }
}
resource "aws_route_table_association" "db_rt1" {
  subnet_id                 = aws_subnet.db_subnet1.id
  route_table_id            = aws_route_table.db_rt1.id
}

// database subnet 2

resource "aws_subnet" "db_subnet2" {
  vpc_id                    = aws_vpc.vpc.id
  cidr_block                = var.cidr_db2
  availability_zone         = var.az_db2
  tags = {
      Environment           =var.environment_tag
      Name                  = "db_subnet2"
  }

}

resource "aws_route_table" "db_rt2" {
  vpc_id                    = aws_vpc.vpc.id
  route {
    cidr_block              = "0.0.0.0/0"
    gateway_id              = aws_nat_gateway.gw.id
  }

  tags = {
    Environment             = var.environment_tag
    Name                    = "rt-db2"
  }
}
resource "aws_route_table_association" "db_rt2" {
  subnet_id                 = aws_subnet.db_subnet2.id
  route_table_id            = aws_route_table.db_rt2.id
}



##output####

output "vpc_id_created" {
  value                     = aws_vpc.vpc.id
}

output "public_subnet_id_created" {
  value                     = aws_subnet.public_ip.id
}
output "app_subnet1_id_created" {
  value                     = aws_subnet.private_app1.id
}

output "app_subnet2_id_created" {
  value                     = aws_subnet.private_app2.id
}

output "db_subnet1_id_created" {
  value                     = aws_subnet.db_subnet1.id
}

output "db_subnet2_id_created" {
  value                     = aws_subnet.db_subnet2.id
}