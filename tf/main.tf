provider "hcloud" {
  token = var.hcloud_token
}

provider "hetznerdns" {
  apitoken = var.hetznerdns_token
}

provider "acme" {
  #server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
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
  count = local.seat_count

  name        = "${var.name}${count.index}"
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
    "owner"   : "${var.name}${count.index}"
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
  count = local.seat_count

  content = templatefile("ssh_config.tpl", {
    node = hcloud_server.vm[count.index].name,
    node_ip = hcloud_server.vm[count.index].ipv4_address
    ssh_key_file = local_file.ssh.filename
  })
  filename = pathexpand("~/.ssh/config.d/${hcloud_server.vm[count.index].name}")
  file_permission = "0644"
}

data "hetznerdns_zone" "main" {
  name = local.domain
}

resource "hetznerdns_record" "main" {
  count = local.seat_count

  zone_id = data.hetznerdns_zone.main.id
  name = hcloud_server.vm[count.index].name
  value = hcloud_server.vm[count.index].ipv4_address
  type = "A"
  ttl= 120
}

resource "hetznerdns_record" "wildcard" {
  count = local.seat_count

  zone_id = data.hetznerdns_zone.main.id
  name = "*.${hcloud_server.vm[count.index].name}"
  value = hetznerdns_record.main[count.index].name
  type = "CNAME"
  ttl= 120
}

resource "tls_private_key" "certificate" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.certificate.private_key_pem
  email_address   = "webmaster@${local.domain}"
}

resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = "${var.name}.${local.domain}"
  subject_alternative_names = concat(
    [for k, vm in hcloud_server.vm : "${vm.name}.${local.domain}"],
    [for k, vm in hcloud_server.vm : "*.${vm.name}.${local.domain}"]
  )
  
  dns_challenge {
    provider = "hetzner"

    config = {
      HETZNER_API_KEY = var.hetznerdns_token
    }
  }
}

# TODO: https://stackoverflow.com/a/62407671
resource "null_resource" "wait_for_ssh" {
  count = local.seat_count

  provisioner "remote-exec" {
    connection {
      host = hcloud_server.vm[count.index].ipv4_address
      user = "root"
      private_key = tls_private_key.ssh_private_key.private_key_openssh
    }

    inline = ["echo 'connected!'"]
  }
}

resource "remote_file" "tls_key" {
  count = local.seat_count

  conn {
    host        = hcloud_server.vm[count.index].ipv4_address
    port        = 22
    user        = "root"
    private_key = tls_private_key.ssh_private_key.private_key_openssh
  }

  path        = "/etc/ssl/tls.key"
  content     = acme_certificate.certificate.private_key_pem
  permissions = "0600"
}

resource "remote_file" "tls_crt" {
  count = local.seat_count

  conn {
    host        = hcloud_server.vm[count.index].ipv4_address
    port        = 22
    user        = "root"
    private_key = tls_private_key.ssh_private_key.private_key_openssh
  }

  path        = "/etc/ssl/tls.crt"
  content     = acme_certificate.certificate.certificate_pem
  permissions = "0644"
}

resource "remote_file" "tls_chain" {
  count = local.seat_count

  conn {
    host        = hcloud_server.vm[count.index].ipv4_address
    port        = 22
    user        = "root"
    private_key = tls_private_key.ssh_private_key.private_key_openssh
  }

  path        = "/etc/ssl/tls.chain"
  content     = acme_certificate.certificate.issuer_pem
  permissions = "0644"
}

resource "remote_file" "vars" {
  depends_on = [
    remote_file.tls_key,
    remote_file.tls_crt,
    remote_file.tls_chain
  ]
  count = local.seat_count

  conn {
    host        = hcloud_server.vm[count.index].ipv4_address
    port        = 22
    user        = "root"
    private_key = tls_private_key.ssh_private_key.private_key_openssh
  }

  path = "/etc/profile.d/vars.sh"
  content = <<EOF
export SEAT_INDEX="${count.index}"
export DOMAIN="${hcloud_server.vm[count.index].name}.${local.domain}"
export IP="${hcloud_server.vm[count.index].ipv4_address}"
export SEAT_USER="${var.name}"
export SEAT_PASS="${local.config.seats[count.index].password}"
export SEAT_CODE="${local.config.seats[count.index].code}"
export SEAT_HTPASSWD="$(htpasswd -nbB seat "$${SEAT_PASS}")"
export SEAT_HTPASSWD_ONLY="$(echo "$${SEAT_HTPASSWD}" | cut -d: -f2)"
export SEAT_CODE_HTPASSWD="$(htpasswd -nbB seat "$${SEAT_CODE}")"
export WEBDAV_PASS_DEV="${local.config.seats[count.index].webdav_pass_dev}"
export WEBDAV_PASS_LIVE="${local.config.seats[count.index].webdav_pass_live}"
export GITLAB_ADMIN_PASS="${local.config.gitlab_admin_password}"
export GITLAB_ADMIN_TOKEN="${local.config.gitlab_admin_token}"
export SEAT_GITLAB_TOKEN="${local.config.seats[count.index].gitlab_token}"
EOF
  permissions = "0755"
}

resource "remote_file" "bootstrap_sh" {
  depends_on = [
    remote_file.vars
  ]
  count = local.seat_count

  conn {
    host        = hcloud_server.vm[count.index].ipv4_address
    port        = 22
    user        = "root"
    private_key = tls_private_key.ssh_private_key.private_key_openssh
  }

  path        = "/opt/bootstrap.sh"
  content = <<EOF
#!/bin/bash
set -o errexit -o pipefail

if test -d ~/container-slides; then
    git -C ~/container-slides pull --all
else
    git clone https://github.com/nicholasdille/container-slides ~/container-slides
fi

cd ~/container-slides/${local.config.bootstrap_directory}
bash bootstrap.sh
EOF
  permissions = "0700"
}

resource "ssh_resource" "bootstrap" {
  depends_on = [
    remote_file.vars,
    remote_file.bootstrap_sh
  ]
  count = local.seat_count

  when = "create"
  host = hcloud_server.vm[count.index].ipv4_address
  user = "root"
  private_key = tls_private_key.ssh_private_key.private_key_openssh
  timeout = "10m"
  retry_delay = "5s"
  commands = [
    remote_file.bootstrap_sh.path
  ]
}