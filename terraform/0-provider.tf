terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3" {
    bucket = "chaos-ipa-test-terraformstate"
    key    = "terraform/state.tfstate"
    region = "us-west-2"
  }
}

variable "cluster_name" {
  default = "eks-chaos-ipa-test"
}

variable "cluster_version" {
  default = "1.29"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

variable "region" {
  default = "us-west-2"
}

variable "registry_server" {
  default = "https://index.docker.io/v1/"
}

variable "registry_username" {
  default = "jusiii"
}

variable "registry_password" {
  // SET IN ENV VAR
  // export TF_VAR_registry_password='secret'
}

variable "registry_email" {
  default = "winistoerfer.justin@gmx.ch"
}