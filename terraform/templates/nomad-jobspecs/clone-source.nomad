job "clone-source" {
    datacenters = [${datacenters}]

    type = "batch"

    parameterized {
        payload = "required"
    }

    group "clone-source" {
        restart {
            attempts = 0
            mode = "fail"
        }

        task "cloner" {
            driver = "raw_exec"

            config {
                command = "${command}"
                args = [
                    "$${NOMAD_TASK_DIR}/config.json",
                    "$${NOMAD_TASK_DIR}/ci-job-builder",
                ]
            }

            env {
                AWS_ACCESS_KEY_ID     = "minio"
                AWS_SECRET_ACCESS_KEY = "freestorage"
                AWS_DEFAULT_REGION    = "us-east-1"
                AWS_S3_ENDPOINT       = "http://127.0.0.1:9000"
                BUCKET                = "clone-source"
            }

            dispatch_payload {
                file = "config.json"
            }

            template {
                destination = "local/ci-job-builder"
                change_mode = "noop"

                data = <<__tmpl_job_builder
{{- with service "ci-job-builder" }}{{ with index . 0 -}}
{{ .Address }}:{{ .Port }}
{{- end }}{{ end }}
__tmpl_job_builder
            }
        }
    }
}
