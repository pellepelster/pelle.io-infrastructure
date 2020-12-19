output "public_ip" {
  value = hcloud_floating_ip.www.ip_address
}