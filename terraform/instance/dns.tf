module "dns_pelle_io" {
  source = "../modules/zone"
  ip_address = hcloud_floating_ip.www.ip_address
  zone_id = data.hetznerdns_zone.dns_zone.id
}
