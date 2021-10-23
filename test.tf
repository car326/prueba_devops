provider "aws" {

 region     = "us-east-1"
}

resource "aws_vpc" "app-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true" 
    enable_dns_hostnames = "true"
    enable_classiclink = "false"
    instance_tenancy = "default"
    
    tags = {
        Name = "app-vpc"
    }
}


resource "aws_subnet" "app-subnet-public-1" {
    vpc_id = "${aws_vpc.app-vpc.id}"
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1a"
    tags = {
        Name = "app-subnet-public-1"
    }
}

resource "aws_subnet" "app-subnet-public-2" {
    vpc_id = "${aws_vpc.app-vpc.id}"
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1b"
    tags = {
        Name = "app-subnet-public-2"
    }
}

resource "aws_subnet" "app-subnet-private-1" {
    vpc_id = "${aws_vpc.app-vpc.id}"
    cidr_block = "10.0.3.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1a"
    tags = {
        Name = "app-subnet-private-1"
    }
}

resource "aws_subnet" "app-subnet-private-2" {
    vpc_id = "${aws_vpc.app-vpc.id}"
    cidr_block = "10.0.4.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1b"
    tags = {
        Name = "app-subnet-private-2"
    }
}

resource "aws_subnet" "db-subnet-private-1" {
    vpc_id = "${aws_vpc.app-vpc.id}"
    cidr_block = "10.0.5.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1a"
    tags = {
        Name = "db-subnet-private-1"
    }
}

resource "aws_subnet" "db-subnet-private-2" {
    vpc_id = "${aws_vpc.app-vpc.id}"
    cidr_block = "10.0.6.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1b"
    tags = {
        Name = "db-subnet-private-2"
    }
}

resource "aws_internet_gateway" "app-igw" {
    vpc_id = "${aws_vpc.app-vpc.id}"
    tags = {
        Name = "app-igw"
    }
}


resource "aws_eip" "nat-app" {
}

resource "aws_nat_gateway" "app-natgw" {
  allocation_id = "${aws_eip.nat-app.id}"
  subnet_id     = "${aws_subnet.app-subnet-public-1.id}"

  tags = {
    Name = "app-natgw"
  }
}


###Route Tables###

resource "aws_route_table" "app-public-crt" {
    vpc_id = "${aws_vpc.app-vpc.id}"
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.app-igw.id}"
    }
    
    tags = {
        Name = "app-public-crt"
    }
}

resource "aws_route_table" "app-private-crt" {
    vpc_id = "${aws_vpc.app-vpc.id}"
    
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${aws_nat_gateway.app-natgw.id}"
    }

    tags = {
        Name = "app-private-crt"
    }
}


resource "aws_route_table_association" "app-crta-public-subnet-1" {
    subnet_id = "${aws_subnet.app-subnet-public-1.id}"
    route_table_id = "${aws_route_table.app-public-crt.id}"

 }

resource "aws_route_table_association" "app-crta-public-subnet-2" {
    subnet_id = "${aws_subnet.app-subnet-public-2.id}"
    route_table_id = "${aws_route_table.app-public-crt.id}"
}

resource "aws_route_table_association" "app-crta-private-subnet-1" {
    subnet_id = "${aws_subnet.app-subnet-private-1.id}"
    route_table_id = "${aws_route_table.app-private-crt.id}"

 }

resource "aws_route_table_association" "app-crta-private-subnet-2" {
    subnet_id = "${aws_subnet.app-subnet-private-2.id}"
    route_table_id = "${aws_route_table.app-private-crt.id}"

 }

 resource "aws_route_table_association" "db-crta-private-subnet-1" {
    subnet_id = "${aws_subnet.db-subnet-private-1.id}"
    route_table_id = "${aws_route_table.app-private-crt.id}"

 }

resource "aws_route_table_association" "db-crta-private-subnet-2" {
    subnet_id = "${aws_subnet.db-subnet-private-2.id}"
    route_table_id = "${aws_route_table.app-private-crt.id}"

 }

###Security Groups###

 resource "aws_security_group" "web" {
  vpc_id = "${aws_vpc.app-vpc.id}"
  name = "web"
  description = "Web Security Group"
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  } 
  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
   tags = {
        Name = "web-sg"
    }

}

resource "aws_security_group" "bastion" {
  vpc_id = "${aws_vpc.app-vpc.id}"
  name = "bastion"
  description = "Bastion Security Group"
  
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }    
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
   tags = {
        Name = "bastion-sg"
    }

}

resource "aws_security_group" "rds" {
   vpc_id = "${aws_vpc.app-vpc.id}"
  name = "rds"
  description = "RDS Security Group"
  
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["10.0.3.0/24"]
  }  
  
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["10.0.4.0/24"]
  } 
 

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
   tags = {
        Name = "rds-sg"
    }

}

resource "aws_security_group" "lb-sg" {
  vpc_id = "${aws_vpc.app-vpc.id}"
  name = "lb-sg"
  description = "LB Security Group"
  
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }    
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
   tags = {
        Name = "lb-sg"
    }

}

###Instances EC2###

resource "aws_instance" "bastion" {
  ami                         = "ami-00068cd7555f543d5"
  instance_type               = "t2.micro"
  key_name                    = "test-lab"
  vpc_security_group_ids      = ["${aws_security_group.bastion.id}"]
  subnet_id                   = "${aws_subnet.app-subnet-public-1.id}"
  associate_public_ip_address = "true"
  
  root_block_device {
    volume_size = "8"
    volume_type = "gp2"
    delete_on_termination = "true"
    }

  tags = {
    Name = "bastion-server"
  }
}

resource "aws_instance" "web-server-aza" {
  ami                         = "ami-00068cd7555f543d5"
  instance_type               = "t2.micro"
  key_name                    = "test-lab"
  vpc_security_group_ids      = ["${aws_security_group.web.id}"]
  subnet_id                   = "${aws_subnet.app-subnet-private-1.id}"
  associate_public_ip_address = "false"

  root_block_device {
    volume_size = "8"
    volume_type = "gp2"
    delete_on_termination = "true"
    }

user_data = <<-EOF
              #!/bin/bash
              sudo yum install python3 -y
              pip3 install PyMySQL 
              sudo yum install httpd -y
              sudo service httpd start
              echo "Hola mundo-server1" >> /var/www/html/index.html
              EOF     

  tags = {
    Name = "web-server-aza"
  }
}

resource "aws_instance" "web-server-azb" {
  ami                            = "ami-00068cd7555f543d5"
  instance_type                  = "t2.micro"
  key_name                       = "test-lab"
  vpc_security_group_ids         = ["${aws_security_group.web.id}"]
  subnet_id                      = "${aws_subnet.app-subnet-private-2.id}"
  associate_public_ip_address    = "false"

  root_block_device {
    volume_size = "8"
    volume_type = "gp2"
    delete_on_termination = "true"
    }

user_data = <<-EOF
              #!/bin/bash
              sudo yum install python3 -y
              pip3 install PyMySQL 
              sudo yum install httpd -y
              sudo service httpd start
              echo "Hola mundo-server2" >> /var/www/html/index.html
              EOF

  tags = {
    Name = "web-server-azb"
  }
}

resource "aws_lb" "test" {
  name               = "test-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb-sg.id}"]
  subnets = [aws_subnet.app-subnet-public-1.id, aws_subnet.app-subnet-public-2.id]

}

resource "aws_lb_target_group" "tg-test" {
  name = "alb-tg"
  port =  80
  vpc_id = "${aws_vpc.app-vpc.id}"
  protocol = "HTTP"

health_check {
  enabled  = "true"
  matcher  = "200"
  path     = "/"
  port     = "80"
  protocol = "HTTP"
 }
}

resource "aws_lb_target_group_attachment" "webserver-1" {
  target_group_arn = aws_lb_target_group.tg-test.arn
  target_id = aws_instance.web-server-aza.id
  port = 80
}

resource "aws_lb_target_group_attachment" "webserver-2" {
  target_group_arn = aws_lb_target_group.tg-test.arn
  target_id = aws_instance.web-server-azb.id
  port = 80
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.test.arn
  port = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg-test.arn
    type = "forward"
  }
}


###RDS Instance##

resource "aws_db_subnet_group" "test-rds" {
  name        = "test_subnet_group"
  description = "test group of subnets"
  subnet_ids  = ["${aws_subnet.db-subnet-private-1.id}", "${aws_subnet.db-subnet-private-2.id}"]
}

resource "aws_db_instance" "rds-test" {
  identifier             = "my-rds"
  allocated_storage      = "100"
  engine                 = "mysql"
  engine_version         = "8.0.25"
  instance_class         = "db.m5.large"
  name                   = "test"
  username               = "admin"
  password               = "Teslab123#"
  vpc_security_group_ids = ["${aws_security_group.rds.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.test-rds.id}"
  multi_az               = "true"
  skip_final_snapshot    = "true"
}