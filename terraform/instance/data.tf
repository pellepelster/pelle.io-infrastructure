data "template_file" "user_data" {

  template = file("user_data.sh")

  vars = {
    public_ip = hcloud_floating_ip.www.ip_address

    github_owner = var.github_owner
    github_token = var.github_token

    storage_device = data.hcloud_volume.data.linux_device

    domain = var.domain
    hostname = var.hostname

    ssh_identity_ecdsa_key = var.ssh_identity_ecdsa_key
    ssh_identity_ecdsa_pub = var.ssh_identity_ecdsa_pub

    ssh_identity_rsa_key = var.ssh_identity_rsa_key
    ssh_identity_rsa_pub = var.ssh_identity_rsa_pub

    ssh_identity_ed25519_key = var.ssh_identity_ed25519_key
    ssh_identity_ed25519_pub = var.ssh_identity_ed25519_pub

    certificate = base64encode(acme_certificate.default_certificate.certificate_pem)
    private_key = base64encode(acme_certificate.default_certificate.private_key_pem)

    deploy_public_key = var.deploy_ssh_public_key
    
  }
}

data "hcloud_volume" "data" {
  name = "${var.hostname}-data"
}

data "hetznerdns_zone" "dns_zone" {
  name = var.domain
}
