terraform {
  required_providers {
    hetznerdns = {
      source = "timohirt/hetznerdns"
      version = "1.1.1"
    }
  }

  required_version = ">= 0.13"
}

resource "hetznerdns_record" "root" {
  zone_id = var.zone_id
  name = "@"
  value = var.ip_address
  type = "A"
  ttl = 60
}

resource "hetznerdns_record" "spf" {
  zone_id = var.zone_id
  name = "@"
  value = "v=spf1 include:mailbox.org"
  type = "TXT"
  ttl = 60
}

resource "hetznerdns_record" "mx_10" {
  zone_id = var.zone_id
  name = "@"
  value = "10 mxext1.mailbox.org."
  type = "MX"
  ttl = 60
}

resource "hetznerdns_record" "mx_20" {
  zone_id = var.zone_id
  name = "@"
  value = "20 mxext2.mailbox.org."
  type = "MX"
  ttl = 60
}

resource "hetznerdns_record" "mx_30" {
  zone_id = var.zone_id
  name = "@"
  value = "30 mxext3.mailbox.org."
  type = "MX"
  ttl = 60
}

resource "hetznerdns_record" "ns_helium" {
  zone_id = var.zone_id
  name = "@"
  value = "helium.ns.hetzner.de."
  type = "NS"
  ttl = 60
}

resource "hetznerdns_record" "ns_hydrogen" {
  zone_id = var.zone_id
  name = "@"
  value = "hydrogen.ns.hetzner.de."
  type = "NS"
  ttl = 60
}

resource "hetznerdns_record" "ns_oxygen" {
  zone_id = var.zone_id
  name = "@"
  value = "oxygen.ns.hetzner.de."
  type = "NS"
  ttl = 60
}