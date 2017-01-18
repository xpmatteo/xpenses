resource "aws_s3_bucket" "config_bucket" {
    bucket = "mv-free-terraform-experiment-state"
    acl = "public-read"

    cors_rule {
        allowed_headers = ["*"]
        allowed_methods = ["PUT","POST"]
        allowed_origins = ["*"]
        expose_headers = ["ETag"]
        max_age_seconds = 3000
    }

    policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "PublicReadForGetBucketObjects",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::mv-free-terraform-experiment-state/*"
        }
    ]
}
EOF
}

resource "aws_vpc" "workshop_vpc" {
    cidr_block = "10.0.0.0/24"
}

resource "aws_subnet" "public_subnet_1" {
    vpc_id = "${aws_vpc.workshop_vpc.id}"
    availability_zone = "eu-central-1a"
    cidr_block = "10.0.0.0/26"
}

resource "aws_subnet" "public_subnet_2" {
    vpc_id = "${aws_vpc.workshop_vpc.id}"
    availability_zone = "eu-central-1b"
    cidr_block = "10.0.0.64/26"
}

resource "aws_instance" "bastion" {
    ami = "ami-211ada4e"
    subnet_id = "${aws_subnet.public_subnet_1.id}"
    associate_public_ip_address = true
    key_name = "matteo-free"
    instance_type = "t2.micro"
    tags {
        Name = "Bastion"
    }
    vpc_security_group_ids = ["${aws_security_group.bastion_sg.id}"]
}

output "bastion.public_ip" {
    value = "${aws_instance.bastion.public_ip}"
}

resource "aws_internet_gateway" "workshop_gw" {
    vpc_id = "${aws_vpc.workshop_vpc.id}"
}

resource "aws_route_table" "workshop_route_table" {
    vpc_id = "${aws_vpc.workshop_vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.workshop_gw.id}"
    }
}

resource "aws_route_table_association" "route_subnet_1" {
    subnet_id = "${aws_subnet.public_subnet_1.id}"
    route_table_id = "${aws_route_table.workshop_route_table.id}"
}

resource "aws_route_table_association" "route_subnet_2" {
    subnet_id = "${aws_subnet.public_subnet_2.id}"
    route_table_id = "${aws_route_table.workshop_route_table.id}"
}

resource "aws_security_group" "bastion_sg" {
    vpc_id = "${aws_vpc.workshop_vpc.id}"

    ingress {
        from_port = 8
        to_port = 0
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

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
}

resource "aws_security_group" "alb_sg" {
    vpc_id = "${aws_vpc.workshop_vpc.id}"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/24"]
    }
}

resource "aws_security_group" "web_sg" {
    vpc_id = "${aws_vpc.workshop_vpc.id}"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        security_groups = [ "${aws_security_group.alb_sg.id}" ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
           from_port = 22
           to_port = 22
           protocol = "tcp"
           security_groups = [ "${aws_security_group.bastion_sg.id}" ]
    }
}

resource "aws_alb" "workshop_alb" {
  name = "workshop-alb-matteo"
  subnets = ["${aws_subnet.public_subnet_1.id}",
             "${aws_subnet.public_subnet_2.id}"]
  security_groups = ["${aws_security_group.alb_sg.id}"]
}

resource "aws_alb_target_group" "workshop_alb" {
  name = "workshop-alb-target-matteo"
  vpc_id = "${aws_vpc.workshop_vpc.id}"
  port = 80
  protocol = "HTTP"
  health_check {
    matcher = "200,301"
  }
}

resource "aws_alb_listener" "workshop_alb_http" {
  load_balancer_arn = "${aws_alb.workshop_alb.arn}"
  port = 80
  protocol = "HTTP"
  default_action {
    target_group_arn = "${aws_alb_target_group.workshop_alb.arn}"
    type = "forward"
  }
}

output "alb.dns" {
    value = "${aws_alb.workshop_alb.dns_name}"
}

resource "aws_launch_configuration" "workshop_launch_conf" {
    image_id = "ami-211ada4e"
    instance_type = "t2.micro"
    key_name = "matteo-free"
    security_groups = ["${aws_security_group.web_sg.id}"]
    associate_public_ip_address = true
    lifecycle {
        create_before_destroy = true
    }
    user_data = <<EOF
#!/usr/bin/env bash
yum update -y
yum install -y httpd24
service httpd start
EOF
}

resource "aws_autoscaling_group" "workshop_autoscale" {
    vpc_zone_identifier = ["${aws_subnet.public_subnet_1.id}",
                           "${aws_subnet.public_subnet_2.id}"]
    min_size = 2
    max_size = 2
    health_check_type = "EC2"
    health_check_grace_period = 300
    launch_configuration = "${aws_launch_configuration.workshop_launch_conf.id}"
    target_group_arns = ["${aws_alb_target_group.workshop_alb.arn}"]
    enabled_metrics = ["GroupInServiceInstances"]
}
