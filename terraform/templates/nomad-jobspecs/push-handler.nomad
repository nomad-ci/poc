job "push-handler" {
    datacenters = [${datacenters}]

    type = "service"

    group "push-handler" {
        count = 1

        task "push-handler" {
            driver = "raw_exec"
            config {
                command = "${gopath}/src/github.com/nomad-ci/push-handler-service/work/push-handler-service-$${attr.kernel.name}-$${attr.cpu.arch}"
                args = [
                    "--webhook-token-prefix", "${webhook_token_prefix}",
                    "--nomad-addr", "http://127.0.0.1:4646",
                    "--dispatch-job-id", "clone-source",
                ]
            }

            env {
                HTTP_PORT = "$${NOMAD_PORT_http}"
                VAULT_ADDR = "http://127.0.0.1:8200"
                VAULT_TOKEN = "${vault_token}"
            }

            resources {
                network {
                    port "http" {}
                }
            }

            service {
                port = "http"
                tags = [
                    "urlprefix-/notify/push"
                ]

                check {
                    type = "script"
                    command = "/bin/echo"
                    args = ["yep"]
                    interval = "10s"
                    timeout = "5s"
                }
            }
        }
    }
}
