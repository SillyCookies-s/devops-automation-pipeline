terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

resource "aws_security_group" "APP-sg" {
  name_prefix = "APP-sg-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "Mateo" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.APP-sg.id]
  key_name                    = var.key_name

  user_data = base64encode(<<-EOF
          #!/bin/bash

          sudo apt-get update -y
          sudo apt-get upgrade -y

          sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common

          curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
          echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

          sudo apt-get update -y
          sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
          sudo usermod -aG docker ubuntu

          sudo systemctl enable docker
          sudo systemctl start docker

          sudo apt-get install -y openjdk-17-jdk

          sudo update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-17-openjdk-amd64/bin/java 1700
          sudo update-alternatives --set java /usr/lib/jvm/java-17-openjdk-amd64/bin/java

          curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | sudo tee \
            /usr/share/keyrings/jenkins-keyring.asc > /dev/null
          echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
            https://pkg.jenkins.io/debian binary/ | sudo tee \
            /etc/apt/sources.list.d/jenkins.list > /dev/null

          sudo apt-get update -y
          sudo apt-get install -y jenkins
          sudo usermod -aG docker jenkins
          sudo systemctl enable jenkins
          sudo systemctl start jenkins
          sudo systemctl restart jenkins
          echo "Jenkins Initial Admin Password:"
          sudo cat /var/lib/jenkins/secrets/initialAdminPassword

          echo "Status: Jenkins and Docker are installed."
        
        EOF
  )
  tags = {
    Name = var.instance_name
  }
}

