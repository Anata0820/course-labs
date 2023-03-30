terraform {
  backend "s3" {
    bucket         = "anata-s3-bucket-newzealand"
    key            = "mytfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "tfstate-terraform"
    encrypt        = true
  }
}