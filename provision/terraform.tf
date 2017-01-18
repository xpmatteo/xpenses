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

resource "aws_instance" "bastion" {
    ami = "ami-211ada4e"
    subnet_id = "${aws_subnet.public_subnet_1.id}"
    associate_public_ip_address = true
    key_name = "matteo-free"
    instance_type = "t2.micro"
    tags {
        Name = "Bastion"
    }
}
