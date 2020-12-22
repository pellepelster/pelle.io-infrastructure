module "dns_sanne_li" {
  source = "../modules/zone"
  ip_address = hcloud_floating_ip.www.ip_address
  zone_id = data.hetznerdns_zone.sanne_li_dns_zone.id
}

data "hetznerdns_zone" "sanne_li_dns_zone" {
  name = "sanne.li"
}

module "dns_pellepelster_de" {
  source = "../modules/zone"
  ip_address = hcloud_floating_ip.www.ip_address
  zone_id = data.hetznerdns_zone.pellepelster_de_dns_zone.id
}

data "hetznerdns_zone" "pellepelster_de_dns_zone" {
  name = "pellepelster.de"
}