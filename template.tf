resource "aws_launch_template" "asg-template" {
  name                                    = "${var.component}-${var.ENV}"
  image_id                                = data.aws_ami.ami.id
  instance_initiated_shutdown_behavior    = "terminate"
  vpc_security_group_ids                  = [aws_security_group.sg.id]
  instance_market_options {
    market_type                           = "spot"
  }
  instance_type                           = "t3.small"
  tag_specifications {
    resource_type                         = "instance"
    tags                                  = {
      Name                                = var.component
    }
  }
}

resource "aws_lb_target_group" "tg" {
  name                                    = "${var.component}-${var.ENV}"
  port                                    = var.APP_PORT
  protocol                                = "HTTP"
  vpc_id                                  = var.VPC_ID
  health_check  {
    path                                  = var.HEALTH
  }
}


resource "aws_autoscaling_group" "asg" {
  name                                    = "${var.component}-${var.ENV}"
  vpc_zone_identifier                     = var.SUBNETS
  desired_capacity                        = var.DESIRED
  max_size                                = var.MIN
  min_size                                = var.MAX
  target_group_arns                       = [ aws_lb_target_group.tg.arn ]

  launch_template {
    id                                    = aws_launch_template.asg-template.id
    version                               = "$Latest"
  }
}


resource "aws_security_group" "sg" {
  name                                    = "allow_access_for_${var.component}-${var.ENV}"
  description                             = "allow_access_for_${var.component}-${var.ENV}"
  vpc_id                                  = var.VPC_ID

  ingress {
    description                           = "SSH"
    from_port                             = 22
    to_port                               = 22
    protocol                              = "tcp"
    cidr_blocks                           = [var.VPC_CIDR, var.MGMT_CIDR]
  }

  ingress {
    description                           = "PROMETHEUS"
    from_port                             = 9100
    to_port                               = 9100
    protocol                              = "tcp"
    cidr_blocks                           = [var.VPC_CIDR, var.MGMT_CIDR]
  }

  ingress {
    description                           = "APP"
    from_port                             = var.APP_PORT
    to_port                               = var.APP_PORT
    protocol                              = "tcp"
    cidr_blocks                           = [var.VPC_CIDR]
  }

  egress {
    from_port                             = 0
    to_port                               = 0
    protocol                              = "-1"
    cidr_blocks                           = ["0.0.0.0/0"]
  }

  tags = {
    Name                                  = "allow_access_for_${var.component}"
  }
}
