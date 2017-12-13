data "template_file" "nomad_fabio" {
    template = "${file("${path.module}/templates/nomad-jobspecs/fabio.nomad")}"

    vars {
        consul_addr = "${var.consul_addr}"
        datacenters = "\"${join(",", var.nomad_datacenters)}\""
    }
}

resource "nomad_job" "fabio" {
    jobspec = "${data.template_file.nomad_fabio.rendered}"
}
