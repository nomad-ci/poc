variable "consul_addr" {
    type = "string"
    description = "address for consul agent"
    default = "127.0.0.1:8500"
}

variable "nomad_datacenters" {
    type = "list"
    description = "list of nomad datacenters"
    default = ["dc1"]
}

variable "github_secret" {
    type = "string"
    description = "secret provided to github to sign webhook requests"
    default = "011746565c10e8c64df18d8724bc542da584433c"
}

variable "github_auth_token" {
    type = "string"
    description = "'token' provided to github as part of webhook path"
    default = "some-auth-token"
}

variable "gopath" {
    type = "string"
    description = "GOPATH where binaries were built"
}

variable "vault_token" {
    type = "string"
    description = "vault token used by "
}
