# 1. The VPC (The Big Box)
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "titan-fintech-vpc" }
}

# 2. Public Subnet (Zone A - For Load Balancer/Bastion)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "titan-public-a"
    "kubernetes.io/role/elb" = "1" # Required for EKS Public LB
  }
}

# 3. Private Subnet (Zone A - For EKS/Database)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "titan-private-a"
    "kubernetes.io/role/internal-elb" = "1" # Required for EKS Internal LB
  }
}

# 4. Internet Gateway (The Door to Internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "titan-igw" }
}

# 5. Public Route Table (Traffic -> IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "titan-public-rt" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# 6. NAT Gateway (The Bridge for Private Subnet)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = { Name = "titan-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id # Must be in Public!
  tags = { Name = "titan-nat-gateway" }
  depends_on = [aws_internet_gateway.igw]
}

# 7. Private Route Table (Traffic -> NAT)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = { Name = "titan-private-rt" }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}