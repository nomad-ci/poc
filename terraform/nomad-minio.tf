data "template_file" "nomad_minio" {
    template = "${file("${path.module}/templates/nomad-jobspecs/minio.nomad")}"

    vars {
        datacenters = "\"${join(",", var.nomad_datacenters)}\""
    }
}

resource "nomad_job" "minio" {
    jobspec = "${data.template_file.nomad_minio.rendered}"
}
