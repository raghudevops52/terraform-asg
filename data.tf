data "aws_ami" "ami" {
  most_recent      = true
  name_regex       = "^${var.component}"
  owners           = ["self"]
}

