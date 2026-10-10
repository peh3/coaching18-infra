terraform {
  backend "s3" {
    bucket = "sctp-tfstate-ce13"
    key    = "tk\tf-coaching18-infra-github-iam-boostrap.tfstate"
    #use_lockfile = true
    region = "us-east-1"
  }
}