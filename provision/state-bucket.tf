
resource "aws_s3_bucket" "state_bucket" {
  bucket = "${var.project_name}.tfstate"
  acl = "private"
  versioning {
    enabled = true
  }
  tags {
    Name = "Terraform State for ${var.project_name}"
  }
}

/*data "terraform_remote_state" "master_state" {
  backend = "s3"
  config {
    bucket = "${var.project_name}.tfstate"
    region = "${var.aws_region}"
    key = "network/${var.environment}/terraform.tfstate"
  }
}*/

