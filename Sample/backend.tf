terraform {
  backend "s3" {
    bucket = "wrokshopproject"
    region = "us-west-2"
    key    = "wrokshopproject/terraform.tfstate"
  }
}