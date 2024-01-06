provider "aws" {
    region = "us-west-2"
  
}


resource "aws_instance" "example" {
  ami           = "ami-008fe2fc65df48dac"
  instance_type = "t2.micro"
  subnet_id = "subnet-0d6e3655d55ad86c3"
  key_name = "Devops"

  provisioner "remote-exec" {
    inline = [
       "sudo apt-get update",
      "sudo apt-get install -y nginx"
    ]
  }
            
}