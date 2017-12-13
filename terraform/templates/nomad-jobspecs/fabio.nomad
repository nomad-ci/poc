job "fabio" {
    datacenters = [${datacenters}]

    type = "service"

    group "fabio" {
        count = 1

        task "fabio" {
            # driver = "docker"

            # config {
            #     image = "fabiolb/fabio"

            #     network_mode = "host"
            #     port_map {
            #         ui = 9998
            #         proxy = 9999
            #     }
            # }

            driver = "raw_exec"
            config {
                command = "fabio"
            }

            artifact {
                source = "https://github.com/fabiolb/fabio/releases/download/v1.5.3/fabio-1.5.3-go1.9.2-$${attr.kernel.name}_$${attr.cpu.arch}"
                destination = "fabio"
                mode = "file"
            }

            env {
                registry_consul_addr = "${consul_addr}"
                proxy_addr = ":$${NOMAD_PORT_proxy}"

                registry_consul_register.addr = ":$${NOMAD_PORT_ui}"
                ui_addr = ":$${NOMAD_PORT_ui}"
            }

            resources {
                network {
                    port "proxy" {
                        static = 9992
                    }

                    port "ui" {}
                }
            }

            service {
                port = "proxy"

                check {
                    type = "http"

                    port = "ui"
                    path = "/health"

                    interval = "1s"
                    timeout = "1s"
                }
            }
        }
    }
}
