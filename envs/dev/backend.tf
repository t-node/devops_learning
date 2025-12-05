terraform {
  backend "s3" {
    bucket = "tfstate-ap-south-1-ks93h1demo" # create this once
    key    = "capstone/dev/terraform.tfstate"
    region = "ap-south-1"
    #dynamodb_table = "terraform-lock" # create this too
    #encrypt        = true
    use_lockfile = true
  }
}
