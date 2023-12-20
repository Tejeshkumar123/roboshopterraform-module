#############create i am policy in terraform#############
resource "aws_iam_policy" "policy" {
  name        = "${var.component}.${var.env}.ssm.policy"
  path        = "/"
  description = "My test policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
#############create i am role in terraform#############
resource "aws_iam_role" "role" {
  name = "${var.component}.${var.env}.ec2role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}
#############i am instance profile#############
resource "aws_iam_instance_profile" "profile" {
  name = "${var.component}.${var.env}"
  role = aws_iam_role.role.name
}
#############i am policy attachment#############
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}
############# create ec2 instance using terraform ####
resource "aws_instance" "web" {
  ami           = data.aws_ami.example.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = "${var.component}.${var.env}"
  }
}
############create route53 using terraform####################
resource "aws_route53_record" "www" {
  zone_id = "Z09755513LWICQ8RRTK8W"
  name    = "${var.component}.${var.env}"
  type    = "A"
  ttl     = 300
  records = [aws_instance.web.private_ip]
}
############create provisioners in terraform##############
resource "null_resource" "null" {
  depends_on = [aws_instance.web,aws_route53_record.www]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "centos"
      password = "DevOps321"
      host     = aws_instance.web.public_ip
    }
    inline = [
      "sudo labauto ansible",
      "ansible-pull -i localhost, -U https://github.com/Tejeshkumar123/drycode-ansible.git roboshop.yml -e env=dev -e role_name=${var.component}"
    ]
  }
}

#################security group terraform#####################
resource "aws_security_group" "sg" {
  name        = "${var.component}.${var.env}"
  description = "Allow TLS inbound traffic"

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.component}.${var.env}"
  }
}