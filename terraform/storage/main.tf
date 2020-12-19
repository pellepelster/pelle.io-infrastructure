terraform {
  required_providers {
    hcloud = {
      source = "terraform-providers/hcloud"
      version = "1.23.0"
    }
  }

  required_version = ">= 0.13"
}

provider "hcloud" {
  token = var.cloud_api_token
}

resource "hcloud_volume" "storage" {
  name = "${var.hostname}-data"
  size = 64
  format = "ext4"
  location = var.location
}