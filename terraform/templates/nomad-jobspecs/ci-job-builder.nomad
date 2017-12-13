job "ci-job-builder" {
    datacenters = [${datacenters}]

    type = "service"

    group "ci-job-builder" {
        count = 1

        task "ci-job-builder" {
            driver = "raw_exec"
            config {
                command = "${gopath}/src/github.com/nomad-ci/ci-job-builder-service/work/ci-job-builder-service-$${attr.kernel.name}-$${attr.cpu.arch}"
                args = [
                    "--nomad-addr", "http://127.0.0.1:4646",
                ]
            }

            env {
                HTTP_PORT = "$${NOMAD_PORT_http}"
            }

            resources {
                network {
                    port "http" {}
                }
            }

            service {
                name = "$${JOB}"
                port = "http"

                ## not exposed via fabio
                tags = []
            }
        }
    }
}
