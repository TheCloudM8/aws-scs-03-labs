```hcl
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }

  # Remote backend – we’ll create the bucket manually first
  backend "s3" {
    bucket         = "thecloudm8-scs-c03-terraform-state"
    key            = "domain6-governance.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}