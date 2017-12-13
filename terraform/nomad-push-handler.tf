locals {
    vault_webhook_token_prefix = "secret/webhook-tokens"
}

data "template_file" "nomad_push_handler" {
    template = "${file("${path.module}/templates/nomad-jobspecs/push-handler.nomad")}"

    vars {
        datacenters = "\"${join(",", var.nomad_datacenters)}\""
        gopath = "${var.gopath}"
        vault_token = "${var.vault_token}"
        webhook_token_prefix = "${local.vault_webhook_token_prefix}"
    }
}

resource "nomad_job" "push_handler" {
    jobspec = "${data.template_file.nomad_push_handler.rendered}"
}

resource "vault_generic_secret" "github_token" {
    path = "${local.vault_webhook_token_prefix}/github/${var.github_auth_token}"
    data_json = "${jsonencode(map(
        "secret",
        var.github_secret,
    ))}"
}
