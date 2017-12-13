provider "nomad" {
    address = "http://127.0.0.1:4646"
}

provider "vault" {
    address = "http://127.0.0.1:8200"
    token = "${var.vault_token}"
}
