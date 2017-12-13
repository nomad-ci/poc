#!/bin/bash
# shellcheck disable=SC1091
set -e -u -o pipefail

cd /tmp

apt-get update
apt-get install -y docker.io unzip make gcc jq awscli

{
    curl -sLfS -o nomad.zip 'https://releases.hashicorp.com/nomad/0.7.0/nomad_0.7.0_linux_amd64.zip'
    unzip nomad.zip
    mv nomad /usr/local/bin/
    rm nomad.zip

    echo 'complete -C /usr/local/bin/nomad nomad' > /etc/profile.d/nomad-autocomplete.sh
} &

{
    curl -sLfS -o consul.zip 'https://releases.hashicorp.com/consul/1.0.1/consul_1.0.1_linux_amd64.zip'
    unzip consul.zip
    mv consul /usr/local/bin/
    rm consul.zip
} &

{
    curl -sLfS -o vault.zip 'https://releases.hashicorp.com/vault/0.9.0/vault_0.9.0_linux_amd64.zip'
    unzip vault.zip
    mv vault /usr/local/bin/
    rm vault.zip

    echo "export VAULT_ADDR='http://127.0.0.1:8200'" > /etc/profile.d/vault.sh
} &

{
    curl -sLfS -o terraform.zip 'https://releases.hashicorp.com/terraform/0.11.1/terraform_0.11.1_linux_amd64.zip'
    unzip terraform.zip
    mv terraform /usr/local/bin/
    rm terraform.zip
} &

{
    curl -sLfS -o go.tar.gz 'https://redirector.gvt1.com/edgedl/go/go1.9.2.linux-amd64.tar.gz'
    tar -C /usr/local -xzf go.tar.gz
    # shellcheck disable=SC2016
    echo 'export PATH="/usr/local/go/bin:${PATH}"' > /etc/profile.d/golang.sh

    curl -sLfS -o /usr/local/bin/dep https://github.com/golang/dep/releases/download/v0.3.2/dep-linux-amd64
    chmod +x /usr/local/bin/dep
}

wait

## start services
systemd-run --unit vault vault server -dev
systemd-run --unit consul consul agent -dev
systemd-run --unit nomad nomad agent -dev -bind 0.0.0.0

## source env vars for the following steps
source /etc/profile.d/vault.sh
source /etc/profile.d/golang.sh

## wait for vault to be ready
while ! vault status &>/dev/null ; do
    echo "waiting for vault"
    sleep 1
done

## find the vault root token and stash it for later
journalctl -o cat -u vault | grep -E '^Root Token: ' | cut -b 13- > /run/vault-token
chmod 444 /run/vault-token

## build binaries
# this doesn't work in /vagrant; something to do with dep and lockfiles
export GOPATH=/tmp/gopath
mkdir -p ${GOPATH}/src/github.com/nomad-ci
cd ${GOPATH}/src/github.com/nomad-ci

projects=(
    push-handler-service
    ci-job-builder-service
)
for project in "${projects[@]}" ; do
    git clone "https://github.com/nomad-ci/${project}.git"
    pushd "${project}" >/dev/null
    make
    popd >/dev/null
done

## apply the terraform config to set up the system
cd /vagrant/terraform
jq -n \
    --arg gopath "${GOPATH}" \
    --arg vault_token "$( tr -d '\n' < /run/vault-token )" \
    '{$gopath, $vault_token}' \
    > terraform.tfvars.json

terraform init
terraform plan -input=false -out=terraform.plan
terraform apply terraform.plan

github_secret=$( terraform output github_secret)
github_webhook_path=$( terraform output github_webhook_path)

## show the status of nomad jobs
nomad status

nomad status | tail -n +2 | awk '{print $1}' | while read -r job; do
    echo "==> ${job}"
    nomad status "${job}"
    echo
done

cat <<EOF

    setup complete!

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
EOF
