data "template_file" "nomad_ci_job_builder" {
    template = "${file("${path.module}/templates/nomad-jobspecs/ci-job-builder.nomad")}"

    vars {
        datacenters = "\"${join(",", var.nomad_datacenters)}\""
        gopath = "${var.gopath}"
    }
}

resource "nomad_job" "ci_job_builder" {
    jobspec = "${data.template_file.nomad_ci_job_builder.rendered}"
}
