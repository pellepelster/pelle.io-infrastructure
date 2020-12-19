provider "acme" {
  #server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address = "pelle@pelle.io"
}

resource "acme_certificate" "default_certificate" {
  account_key_pem = acme_registration.registration.account_key_pem
  common_name = var.domain

  dns_challenge {
    provider = "hetzner"

    config = {
      HETZNER_API_KEY = var.dns_api_token
    }
  }
}