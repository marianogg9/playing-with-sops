terraform {
  backend "s3" {
    bucket         = "your_bucket"
    key            = "your_bucket_tfstate_file"
    region         = "your_region"
    dynamodb_table = "your_dynamodb_table"
  }
}