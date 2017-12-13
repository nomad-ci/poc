output "github_webhook_path" {
    value = "/notify/push/github/${var.github_auth_token}"
}

output "github_secret" {
    value = "${var.github_secret}"
}

