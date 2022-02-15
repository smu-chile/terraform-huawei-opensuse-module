output "opensuse_ip" {
  value = huaweicloud_compute_eip_associate.associated.public_ip
}
