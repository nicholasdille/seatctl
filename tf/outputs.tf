output "count" {
    value = local.seat_count
}

output "ssh_public_key" {
  value = "${tls_private_key.ssh_private_key.public_key_openssh}"
}

output "ip" {
    value = {
        for k, vm in hcloud_server.vm : "${vm.name}" => vm.ipv4_address
    }
}