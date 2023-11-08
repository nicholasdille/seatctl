terraform {
  required_providers {
    hcloud = {
      # https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs
      source = "hetznercloud/hcloud"
      version = "1.38.2"
    }
  }
}