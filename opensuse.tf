data "huaweicloud_images_image" "opensuse" {
  name        = "opensuse-rp"
  most_recent = true
}

data "huaweicloud_availability_zones" "myaz" {}


resource "huaweicloud_compute_keypair" "opensuse" {
  name       = "${var.name}-opensuse-keypair"
  public_key = var.public_key
}

resource "huaweicloud_networking_secgroup" "opensuse" {
  name                 = "${var.name}-opensuse-sg"
  description          = "SSH security group"
  delete_default_rules = true
}

resource "huaweicloud_networking_secgroup_rule" "inbound_ssh" {
  for_each          = toset(jsondecode(var.ingress-cidr))
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = each.key
  security_group_id = huaweicloud_networking_secgroup.opensuse.id
}

resource "huaweicloud_networking_secgroup_rule" "inbound_ssh_ansible" {
  count             = var.ingress-cidr-ansible != "" ? 1 : 0
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.ingress-cidr-ansible
  security_group_id = huaweicloud_networking_secgroup.opensuse.id
}


resource "huaweicloud_networking_secgroup_rule" "outbound_ssh" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.opensuse.id
}

resource "huaweicloud_compute_instance" "opensuse" {
  name                        = "${var.name}-opensuse"
  image_id                    = data.huaweicloud_images_image.opensuse.id
  flavor_id                   = var.opensuse_flavor_id
  security_group_ids          = [huaweicloud_networking_secgroup.opensuse.id]
  key_pair                    = huaweicloud_compute_keypair.opensuse.name
  availability_zone           = data.huaweicloud_availability_zones.myaz.names[0]
  delete_disks_on_termination = true

  network {
    uuid = var.subnet_id
  }
  tags = var.default_tags
}

resource "huaweicloud_vpc_eip" "myeip" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.name}-opensuse-eip-bw"
    size        = 8
    share_type  = "PER"
    charge_mode = "traffic"
  }
  tags = var.default_tags
}

resource "huaweicloud_compute_eip_associate" "associated" {
  public_ip   = huaweicloud_vpc_eip.myeip.address
  instance_id = huaweicloud_compute_instance.opensuse.id
}