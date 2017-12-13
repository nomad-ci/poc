## the what

Proof-of-concept for nomad-ci.  Configures a Vagrant box with Nomad, Consul, and
Vault, builds the required components, and uses Terraform to provision the
required jobs.

## the how

    vagrant up --provider virtualbox

Use [ngrok](https://ngrok.com) to expose the fabio proxy port (`9992`) to the Internet.

## and then?

Follow the instructions in the vagrant provisioning output:

    you can use https://ngrok.com to expose port 9992 to the Internet, and then
    add a webhook to a GitHub repo with the following settings:

    Payload URL: https://<id>.ngrok.io/${github_webhook_path}
    Content type: application/json
    Secret: ${github_secret}
    Events: Just the push event

    The stderr logs for the push-handler nomad job should indicate that a ping
    event has been processed.  A push to that repo will:

    * POST to the push-handler job (if the repo has a /.nomadci.yml file)
    * dispatch an instance of clone-source
    * submit a new ci-job/<timestamp> job
