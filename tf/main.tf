provider "hcloud" {
  token = var.hcloud_token
}

resource "tls_private_key" "ssh_private_key" {
  algorithm = "ED25519"
  rsa_bits  = 4096
}

resource "hcloud_ssh_key" "ssh_public_key" {
  name       = var.name
  public_key = tls_private_key.ssh_private_key.public_key_openssh
}

data "hcloud_image" "packer" {
  with_selector = "type=uniget"
  most_recent = true
}

resource "hcloud_server" "vm" {
  for_each = {
    1 = { label_owner = "foo" },
    2 = { label_owner = "bar" }
  }

  name        = "${var.name}${each.key}"
  location    = local.location
  server_type = local.server_type
  image       = data.hcloud_image.packer.id
  ssh_keys    = [
    hcloud_ssh_key.ssh_public_key.name
  ]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  labels = {
    "purpose" : var.name
    "owner"   : each.value.label_owner
  }
}

resource "local_file" "ssh" {
  content = tls_private_key.ssh_private_key.private_key_openssh
  filename = pathexpand("~/.ssh/${var.name}_ssh")
  file_permission = "0600"
}

resource "local_file" "ssh_pub" {
  content = tls_private_key.ssh_private_key.public_key_openssh
  filename = pathexpand("~/.ssh/${var.name}_ssh.pub")
  file_permission = "0644"
}

resource "local_file" "ssh_config_file" {
  for_each = hcloud_server.vm

  content = templatefile("ssh_config.tpl", {
    node = each.value.name,
    node_ip = each.value.ipv4_address
    ssh_key_file = local_file.ssh.filename
  })
  filename = pathexpand("~/.ssh/config.d/${each.value.name}")
  file_permission = "0644"
}