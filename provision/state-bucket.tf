
resource "aws_s3_bucket" "state_bucket" {
  bucket = "${var.project_name}.${var.environment}.tfstate"
  acl = "private"
  versioning {
    enabled = true
  }
  tags {
    Name = "Terraform State for ${var.project_name}"
  }
}

output "state_bucket_id" {
  value = "${aws_s3_bucket.state_bucket.id}"
}

output "state_bucket_arn" {
  value = "${aws_s3_bucket.state_bucket.arn}"
}
