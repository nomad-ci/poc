data "template_file" "nomad_clone_source" {
    template = "${file("${path.module}/templates/nomad-jobspecs/clone-source.nomad")}"

    vars {
        datacenters = "\"${join(",", var.nomad_datacenters)}\""
        command = "${path.module}/files/clone-source.sh"
    }
}

resource "nomad_job" "clone_source" {
    jobspec = "${data.template_file.nomad_clone_source.rendered}"
}
