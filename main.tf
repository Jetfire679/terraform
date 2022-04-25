#Create and bootstrap webserver

terraform {
  cloud {
    organization = "vignalis"
    workspaces {
      name = "terraform"
    }
  }
}


# Create a IAM Policy
resource "aws_iam_policy" "dockerpolicy" {
  name        = join("-", [var.vApp, var.vEnv, "iam-policy"])
  path        = "/"
  description = "docker policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


#Create IAM Role
resource "aws_iam_role" "dockerrole" {
  name = join("-", [var.vApp, var.vEnv, "iam-role"])
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

# Attach Role to Policy
resource "aws_iam_policy_attachment" "ec2docker_policy_role" {
  depends_on = [aws_iam_policy.dockerpolicy]

  name       = "dockerec2_attachment"
  roles      = [aws_iam_role.dockerrole.name]
  policy_arn = aws_iam_policy.dockerpolicy.arn
}

resource "aws_iam_policy_attachment" "ec2docker_policy_role2" {
  depends_on = [aws_iam_policy.dockerpolicy]

  name       = "dockerec2_attachment"
  roles      = [aws_iam_role.dockerrole.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create Instance profile
resource "aws_iam_instance_profile" "dockerprofile" {
  name = join("-", [var.vApp, var.vEnv, "iam-profile"])
  role = aws_iam_role.dockerrole.name
}

# Setup resource so that cfn-init template can be passed to EC2 in user-data
data "template_file" "user_data" {
  template = file("./scripts/cfn-init.yaml")
}

resource "aws_instance" "dockerserver" {
  ami                         = data.aws_ssm_parameter.webserver-ami.value
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.webserver-key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg.id]
  subnet_id                   = module.vpc.public_subnets[0]
  iam_instance_profile = aws_iam_instance_profile.dockerprofile.name
  user_data            = data.template_file.user_data.rendered
  # user_data = "${file("./scripts/cfn-init.yaml")}"
  
  
  # Provisioned block used to do base OS setup
  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo yum update -y",
  #     "sudo amazon-linux-extras install epel -y",
  #     "sudo yum -y install git",
  #     "git clone https://github.com/linuxacademy/content-hashicorp-certified-terraform-associate-foundations.git",
  #     "sudo amazon-linux-extras install ansible2 -y",
  #     "git clone https://github.com/Jetfire679/base.git",
  #     "sudo ansible-playbook /home/ec2-user/base/test.yml"
  #     # "echo 'don't forget to configure the aws profile - aws --profile demo configure'
  #   ]
  #   connection {
  #     type        = "ssh"
  #     user        = "ec2-user"
  #     private_key = file("./files/id_rsa")
  #     host        = self.public_ip
  #   }
  # }


  tags = {
    Name = join("-", [var.vApp, var.vEnv, "ec2"])
  }
}
