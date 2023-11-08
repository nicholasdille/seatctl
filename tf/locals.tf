locals {
    config       = jsondecode(file("seats.json"))
    name         = local.config.name
    domain       = local.config.domain
    location     = local.config.location
    server_type  = local.config.server_type
    seat_count   = local.config.count
}