variable "cloud_api_token" {}

variable "dns_api_token" {}

variable "location" {
  default = "fsn1"
}

variable "github_token" {}
variable "github_owner" {}

variable "domain" {}

variable "hostname" {}

variable "ssh_identity_ecdsa_key" {}
variable "ssh_identity_ecdsa_pub" {}

variable "ssh_identity_rsa_key" {}
variable "ssh_identity_rsa_pub" {}

variable "ssh_identity_ed25519_key" {}
variable "ssh_identity_ed25519_pub" {}

variable "deploy_ssh_public_key" {}
