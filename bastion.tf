locals {
  user_data = <<-EOT
  #!/bin/bash
  sudo yum update -y
  sudo yum install postgresql -y
  EOT
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "bastion-host"

  instance_type          = "t3.micro"
  key_name               = "test"
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id              = aws_subnet.public[0].id
  user_data_base64 = base64encode(local.user_data)

  tags = {
    Terraform   = "true"
    Name = "demo_bastion_host"
  }
}
