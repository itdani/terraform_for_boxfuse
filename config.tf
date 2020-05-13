provider "aws" {
  region  = "eu-central-1"
}

resource "aws_s3_bucket" "dev" {
  bucket = "devupprod.test.com"
  acl    = "public-read"
 }

resource "aws_instance" "dev" {
 ami = "ami-0e342d72b12109f91"
 instance_type = "t2.micro"
 security_groups = ["EC2SecurityGroup"]
 key_name = "my-key"
 tags = {
   Name = "dev"
 }

 connection {
    type        = "ssh"
    user        = "ubuntu"
    agent       = false
    private_key = "${file("~/.ssh/my-key.pem")}"
  } 

 provisioner "file"{
   source      = "~/.aws/credentials"
   destination = "~/credentials"
}

 provisioner "remote-exec" {
    inline = [
     "sudo apt update",
     "sudo apt install -y git",
     "sudo apt install -y default-jdk",
     "sudo apt install -y maven",
     "sudo apt install -y awscli",
     "git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git /tmp/boxfuse/",
     "mvn -f /tmp/boxfuse/pom.xml package",
     "sudo mkdir ~/.aws",
     "sudo mv ~/credentials ~/.aws/credentials", 
     "aws s3 cp /tmp/boxfuse/target/hello-1.0.war s3://devupprod.test.com --acl public-read",
    ]
 }
}

resource "aws_instance" "prod" {
 ami = "ami-0e342d72b12109f91"
 instance_type = "t2.micro"
 security_groups = ["EC2SecurityGroup"]
 key_name = "my-key"
 tags = {
   Name = "prod"
 }

 connection {
    type        = "ssh"
    user        = "ubuntu"
    agent       = false
    private_key = "${file("~/.ssh/my-key.pem")}"
  }

 provisioner "remote-exec" {
    inline = [
     "sudo apt update",
     "sudo apt install -y tomcat8",
     "cd /var/lib/tomcat8/webapps/",
     "sleep 180",
     "sudo wget https://s3.eu-central-1.amazonaws.com/devupprod.test.com/hello-1.0.war",
     "sudo service tomcat8 restart",
    ]
 }
}
