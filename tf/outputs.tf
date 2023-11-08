output "ip" {
    value = {
        for k, vm in hcloud_server.vm : k => vm.ipv4_address
    }
}