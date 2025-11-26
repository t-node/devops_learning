resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "main_vpc"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "main_igw"
    }
}

resource "aws_subnet" "public_a" {
    vpc_id     = aws_vpc.main.id
    cidr_block = var.subnet_cidr
    availability_zone = var.availability_zone
    map_public_ip_on_launch = true
    tags = {
        Name = "public_a_subnet"
    }
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "public_rt"
    }
    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }  
}
resource "aws_route_table_association" "public_a_assoc" {
    subnet_id      = aws_subnet.public_a.id
    route_table_id = aws_route_table.public_rt.id
}

