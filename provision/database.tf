
resource "aws_dynamodb_table" "movements" {
    name = "${var.project_name}.${var.environment}.movements"
    read_capacity = 5
    write_capacity = 5
    hash_key = "movement_id"
    range_key = "date"
    attribute {
      name = "movement_id"
      type = "S"
    }
    attribute {
      name = "date"
      type = "S"
    }
}
