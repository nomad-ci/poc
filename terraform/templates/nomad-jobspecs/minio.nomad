job "minio" {
    datacenters = [${datacenters}]

    type = "service"

    group "minio" {
        count = 1

        ephemeral_disk {
            migrate = true
            sticky = true
            size = "500"
        }

        task "minio" {
            driver = "raw_exec"

            config {
                command = "minio"
                args = [
                    "server",
                    "--address", ":$${NOMAD_PORT_http}",
                    "$${NOMAD_ALLOC_DIR}/data",
                ]
            }

            env {
                MINIO_ACCESS_KEY = "minio"
                MINIO_SECRET_KEY = "freestorage"
            }

            artifact {
                source = "https://dl.minio.io/server/minio/release/$${attr.kernel.name}-$${attr.cpu.arch}/minio"
                destination = "minio"
                mode = "file"
            }

            resources {
                network {
                    mbits = 20
                    port "http" {
                        static = 9000
                    }
                }
            }
        }
    }
}
