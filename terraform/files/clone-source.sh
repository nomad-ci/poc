#!/bin/bash
set -e -u -o pipefail

# NOMAD_ALLOC_DIR=…/alloc/c7d322a8-b805-c663-e639-26e50471cb5e/alloc
# NOMAD_ALLOC_ID=c7d322a8-b805-c663-e639-26e50471cb5e
# NOMAD_ALLOC_INDEX=0
# NOMAD_ALLOC_NAME=build-something/dispatch-1512485647-e3b2b71a.clone[0]
# NOMAD_CPU_LIMIT=100
# NOMAD_DC=dc1
# NOMAD_GROUP_NAME=clone
# NOMAD_JOB_NAME=build-something/dispatch-1512485647-e3b2b71a
# NOMAD_MEMORY_LIMIT=10
# NOMAD_REGION=global
# NOMAD_SECRETS_DIR=…/alloc/c7d322a8-b805-c663-e639-26e50471cb5e/clone/secrets
# NOMAD_TASK_DIR=…/alloc/c7d322a8-b805-c663-e639-26e50471cb5e/clone/local
# NOMAD_TASK_NAME=clone

# {
#   "clone_url": "https://github.com/nomad-ci/push-handler-service.git",
#   "ref": "refs/heads/master",
#   "sha": "024acfdef6b2f11d8b9b2d1e49b9dc401e64ffd7"
# }

s3=(aws)
if [ -n "${AWS_S3_ENDPOINT:-}" ]; then
    s3=( "${s3[@]}" "--endpoint-url" "${AWS_S3_ENDPOINT}" )
fi
s3=( "${s3[@]}" s3 )

payload_path="${1}"
ci_job_builder_target_path="${2}"

clone_url="$( jq -r .clone_url "${payload_path}" )"
sha="$( jq -r .sha "${payload_path}" )"

archive_path="${BUCKET}/${sha}.tar.gz"

mkdir clone_target
pushd clone_target >/dev/null

git clone -- "${clone_url}" .
git checkout "${sha}"

sha_abbrev="$( git rev-parse --short HEAD || true )"
describe="$( git describe HEAD || true )"
describe_ref="$( git describe --all HEAD || true )"
tag="$( git describe --exact-match HEAD || true )"

## submodules
git submodule update --init --recursive

popd >/dev/null

job_cfg="clone_target/.nomadci.yml"

if [ ! -e "${job_cfg}" ]; then
    echo "WARN: .nomadci.yml not found; not archiving"
else
    tar -cz -f archive.tar.gz -C clone_target .

    "${s3[@]}" mv archive.tar.gz "s3://${archive_path}"

    job_builder_payload="$(
        jq -n \
            --arg job_spec "$( cat "${job_cfg}" )" \
            --arg source_archive "s3::${AWS_S3_ENDPOINT:-https://s3.amazonaws.com}/${archive_path}?aws_access_key_id=${AWS_ACCESS_KEY_ID}&aws_access_key_secret=${AWS_SECRET_ACCESS_KEY}" \
            --arg git_sha "${sha}" \
            --arg git_sha_abbrev "${sha_abbrev}" \
            --arg git_describe "${describe}" \
            --arg git_describe_ref "${describe_ref}" \
            --arg git_tag "${tag}" \
            --arg git_remote "${clone_url}" \
            '{
                "source_archive": $source_archive,
                "source_meta": {
                    "git.sha": $git_sha,
                    "git.sha_abbrev": $git_sha_abbrev,
                    "git.describe": $git_describe,
                    "git.describe_ref": $git_describe_ref,
                    "git.tag": $git_tag,
                    "git.remote": $git_remote
                },
                "job_spec": $job_spec
            }'
    )"

    curl \
        -sfS \
        -H 'Content-Type: application/json' \
        -d "${job_builder_payload}" \
        "http://$( cat "${ci_job_builder_target_path}" )/build-job"
fi

rm -rf clone_target
