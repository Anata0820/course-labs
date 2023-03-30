provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_db_instance" "my_database" {
  db_name           = var.database_name
  allocated_storage = 10
  engine            = "mysql"
  instance_class    = "db.t2.micro"
  username          = var.db_username
  password          = var.db_password

  skip_final_snapshot = true
  publicly_accessible = true
  deletion_protection = true


  tags = {
    Name : "${var.env_prefix}-database"
  

}


module "s3_bucket" {
  source      = "../modules/s3-bucket"
  bucket_name = var.bucket_name
}


resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-public-subnet" {
  vpc_id                  = aws_vpc.myapp-vpc.id
  count                   = length(var.subnet_cidrs_public)
  cidr_block              = var.subnet_cidrs_public[count.index]
  availability_zone       = var.avail_zone[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name : "${var.env_prefix}-public-subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "myapp-route-table" {
  vpc_id = aws_vpc.myapp-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name : "${var.env_prefix}-rtb"
  }

}

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id

  tags = {
    Name : "${var.env_prefix}-igw"
  }
}

resource "aws_route_table_association" "a-rtb-subnet" {
  count          = length(var.subnet_cidrs_public)
  subnet_id      = aws_subnet.myapp-public-subnet[count.index].id
  route_table_id = aws_route_table.myapp-route-table.id
}


resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name : "${var.env_prefix}-sg"
  }

}

data "aws_ami" "latest-amazon-ubuntu-image" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.image_name]
  }

  owners = [var.image_owner]


}

resource "aws_key_pair" "ssh-key" {
  key_name   = "server-key"
  public_key = file(var.public_key_location)
}


resource "aws_instance" "myapp-server" {

  count         = length(var.subnet_cidrs_public)
  ami           = data.aws_ami.latest-amazon-ubuntu-image.id
  instance_type = var.intstance_type

  subnet_id              = aws_subnet.myapp-public-subnet[count.index].id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone      = var.avail_zone[count.index]

  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name

  #user_data = file("entry-script.sh")


  tags = {
    Name : "${var.env_prefix}-server-${count.index + 1}"

  }

}




/*module "myapp-public-subnet" {
  source              = "./modules/subnets"
  subnet_cidrs_public = var.subnet_cidrs_public
  env_prefix          = var.env_prefix
  avail_zone          = var.avail_zone
  vpc_id              = aws_vpc.myapp-vpc.id

}

module "myapp-servers" {
  source              = "./modules/webserver"
  vpc_id              = aws_vpc.myapp-vpc.id
  my_ip               = var.my_ip
  intstance_type      = var.intstance_type
  public_key_location = var.public_key_location
  image_name          = var.image_name
  subnet_id           = module.myapp-public-subnet.subnet-2.id
  avail_zone          = var.avail_zone
  env_prefix          = var.env_prefix
} */





