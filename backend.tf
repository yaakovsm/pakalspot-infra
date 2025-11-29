terraform {
  backend "s3" {
    bucket       = "terraform-pakalspot-backend-bucket"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}