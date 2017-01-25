resource "aws_instance" "xpenses_host" {
    ami = "ami-211ada4e"
    associate_public_ip_address = true
    key_name = "${var.key_name}"
    instance_type = "t2.micro"
    tags {
        Name = "XPenses-${var.environment}"
    }
    vpc_security_group_ids = ["${aws_security_group.xpenses_host_sg.id}"]
}

resource "aws_security_group" "xpenses_host_sg" {
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

output "xpenses_host.public_ip" {
    value = "${aws_instance.xpenses_host.public_ip}"
}
