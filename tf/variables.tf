variable "hcloud_token" {
  sensitive = true
}

variable "hetznerdns_token" {
  sensitive = true
}

variable name {
  type = string
  default = "seat"
}

variable user {
  type = string
  default = "seat"
}