#!/usr/bin/env bash

set -o pipefail -o errexit -o nounset
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"

DOMAIN="pelle.io"
GITHUB_OWNER="pellepelster"
GITHUB_REPOSITORY="pelle.io-infrastructure"

DOCKER_REGISTRY="docker.pkg.github.com"
DOCKER_REPOSITORY="${GITHUB_OWNER}/${GITHUB_REPOSITORY}"
DOCKER_IMAGE_NAME_WWW="www"

DOCKER_ARGS="--pull --no-cache"
DOCKER_ARGS=""

source "${DIR}/ctuhl/lib/shell/log.sh"
source "${DIR}/ctuhl/lib/shell/ruby.sh"

trap task_clean SIGINT SIGTERM ERR EXIT

TEMP_DIR="${DIR}/.tmp"
mkdir -p "${TEMP_DIR}"

function task_docker_login {
  pass "infrastructure/${DOMAIN}/github_access_token_rw" | docker login https://docker.pkg.github.com -u ${GITHUB_OWNER} --password-stdin
}

function task_generate_ssh_identities {
  generate_ssh_identity "ecdsa"
  generate_ssh_identity "rsa"
}
function generate_ssh_identity {
  local type="${1}"
  ssh-keygen -q -N "" -t ${type} -f "${TEMP_DIR}/ssh_host_${type}_key"
  pass insert -m "infrastructure/${DOMAIN}/ssh_host_${type}_key" < "${TEMP_DIR}/ssh_host_${type}_key"
  pass insert -m "infrastructure/${DOMAIN}/ssh_host_${type}_public_key" < "${TEMP_DIR}/ssh_host_${type}_key.pub"
}

function generate_deploy_ssh_identity {
  local type="ed25519"
  ssh-keygen -q -N "" -t ${type} -f "${TEMP_DIR}/deploy_ssh"
  pass insert -m "infrastructure/${DOMAIN}/deploy_ssh_key" < "${TEMP_DIR}/deploy_ssh"
  pass insert -m "infrastructure/${DOMAIN}/deploy_ssh_public_key" < "${TEMP_DIR}/deploy_ssh.pub"
}

function task_build {
  (
    cd "${DIR}/www"
    docker build ${DOCKER_ARGS} -t ${DOCKER_IMAGE_NAME_WWW} -f Dockerfile .
    docker tag "${DOCKER_IMAGE_NAME_WWW}" "${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME_WWW}:latest"
  )
}

function task_usage {
  echo "Usage: $0 build | test | deploy"
  exit 1
}

function task_clean {
  echo "cleaning up '${TEMP_DIR}'"
  rm -rf "${TEMP_DIR}"

  cd ${DIR}/www/test/www
  docker-compose rm --force --stop

  docker volume rm -f pelle-www-test-ssl
  docker volume rm -f pelle-www-test-data
}

function terraform_wrapper_do() {
  local directory=${1:-}
  local command=${2:-apply}
  shift || true
  shift || true

  if [ ! -d "${directory}/.terraform" ]; then
    terraform_wrapper "${directory}" init -lock=false
  fi

  terraform_wrapper "${directory}" "${command}" -lock=false "$@"
}

function terraform_wrapper() {
  local directory=${1:-}
  shift || true
  (
      cd "${DIR}/${directory}"
      terraform "$@"
  )
}

function task_infra_instance {
  export TF_VAR_github_token="$(pass "infrastructure/${DOMAIN}/github_access_token_ro")"
  export TF_VAR_github_owner="${GITHUB_OWNER}"
  export TF_VAR_domain="${DOMAIN}"
  export TF_VAR_hostname="www"
  export TF_VAR_cloud_api_token="$(pass "infrastructure/${DOMAIN}/cloud_api_token")"
  export TF_VAR_dns_api_token="$(pass "infrastructure/${DOMAIN}/dns_api_token")"
  export TF_VAR_ssh_identity_ecdsa_key="$(pass "infrastructure/${DOMAIN}/ssh_host_ecdsa_key" | base64 -w 0)"
  export TF_VAR_ssh_identity_ecdsa_pub="$(pass "infrastructure/${DOMAIN}/ssh_host_ecdsa_public_key" | base64 -w 0)"
  export TF_VAR_ssh_identity_rsa_key="$(pass "infrastructure/${DOMAIN}/ssh_host_rsa_key" | base64 -w 0)"
  export TF_VAR_ssh_identity_rsa_pub="$(pass "infrastructure/${DOMAIN}/ssh_host_rsa_public_key" | base64 -w 0)"
  export TF_VAR_ssh_identity_ed25519_key="$(pass "infrastructure/${DOMAIN}/ssh_host_ed25519_key" | base64 -w 0)"
  export TF_VAR_ssh_identity_ed25519_pub="$(pass "infrastructure/${DOMAIN}/ssh_host_ed25519_public_key" | base64 -w 0)"
  export TF_VAR_deploy_ssh_public_key="$(pass "infrastructure/${DOMAIN}/deploy_ssh_public_key" | base64 -w 0)"

  terraform_wrapper_do "terraform/instance" "$@"
}

function task_infra_storage {
  export TF_VAR_hostname="www"
  export TF_VAR_cloud_api_token="$(pass "infrastructure/${DOMAIN}/cloud_api_token")"

  terraform_wrapper_do "terraform/storage" "$@"
}

function task_ssh_instance {
  local public_ip="$(terraform_wrapper "terraform/instance" "output" "-json" | jq -r '.public_ip.value')"
  ssh root@${public_ip} "$@"
}

function task_output {
  terraform_wrapper "terraform/instance" "output" "-json" | jq "$@"
}

function create_snakeoil_certificates {
  local dir="${1}"
  local common_name="${2:-localhost.test}"
  log_divider_header "generating  certificate for '${common_name}"

  openssl genrsa -out "${dir}/private_key.pem" 2048

  cat >${dir}/cert-config.txt <<EOI
[ req ]
distinguished_name     = req_distinguished_name
prompt                 = no
[ req_distinguished_name ]
C                      = DE
ST                     = Test State or Province
L                      = Test Locality
O                      = Test Organization Name
OU                     = Test Organizational Unit Name
CN                     = ${common_name}
emailAddress           = info@${common_name}
EOI
  openssl req -batch -new -key "${dir}/private_key.pem" -out "${dir}/${common_name}.csr" -config "${dir}/cert-config.txt"
  openssl x509 -req -days 365 -in "${dir}/${common_name}.csr" -signkey "${dir}/private_key.pem" -out "${dir}/certificate.pem"
  chmod 666 "${dir}/private_key.pem"
  log_divider_footer
}

function task_test() {
  mkdir -p "${TEMP_DIR}/ssl"
  create_snakeoil_certificates "${TEMP_DIR}/ssl"

  docker volume rm -f pelle-www-test-ssl
  docker run --rm -v "${TEMP_DIR}/ssl:/src" -v www-test-ssl:/data busybox cp -rv /src /data/default

  docker volume rm -f pelle-www-test-data
  docker run --rm -v "${DIR}/www/test/www:/src" -v www-test-data:/data busybox cp -rv /src/index.html /data/index.html
  docker run --rm -v "${DIR}/www/test/www:/src" -v www-test-data:/data busybox cp -rv /src/test.js /data/test.js
  docker run --rm -v "${DIR}/www/test/www:/src" -v www-test-data:/data busybox cp -rv /src/test.css /data/test.css

  (
    cd ${DIR}/www/test
    cthul_ruby_ensure_bundle
    bundle exec ruby runner.rb www
  )
}

function task_run() {
  mkdir -p "${TEMP_DIR}/ssl"
  create_snakeoil_certificates "${TEMP_DIR}/ssl"

  docker volume rm -f pelle-www-test-ssl
  docker run --rm -v "${TEMP_DIR}/ssl:/src" -v www-test-ssl:/data busybox cp -rv /src /data/default

  docker volume rm -f pelle-www-test-data
  docker run --rm -v "${DIR}/www/test/www:/src" -v www-test-data:/data busybox cp -rv /src/ /data/

  (
    cd ${DIR}/www/test/www
    docker-compose up -d
    local ssl_port="$(docker inspect www_www_1 | jq -r '.[0].NetworkSettings.Ports["443/tcp"][0].HostPort')"
    echo "www is running at https://localhost:${ssl_port}"
    echo "press any key to shutdown"
    read
  )
}

function task_deploy {
  docker push "${DOCKER_REGISTRY}/${DOCKER_REPOSITORY}/${DOCKER_IMAGE_NAME_WWW}:latest"
}

function task_deploy_html {
  local dir=${1:-}

  pass "infrastructure/${DOMAIN}/deploy_ssh_key" > "${TEMP_DIR}/deploy_ssh"
  chmod 600 "${TEMP_DIR}/deploy_ssh"

  echo "put -R ${dir}/*" > "${TEMP_DIR}/deploy_batch"
  echo "exit" >> "${TEMP_DIR}/deploy_batch"
  #sftp -b "${TEMP_DIR}/deploy_batch" -i "${TEMP_DIR}/deploy_ssh" deploy@pelle.io
  sftp -i "${TEMP_DIR}/deploy_ssh" deploy@pelle.io
}

function task_set_github_access_token_rw {
  echo "Enter the Github personal read/write access token, followed by [ENTER]:"
  read -r github_access_token
  echo ${github_access_token} | pass insert -m "infrastructure/${DOMAIN}/github_access_token_rw"
}

function task_set_github_access_token_ro {
  echo "Enter the Github personal readonly access token, followed by [ENTER]:"
  read -r github_access_token
  echo ${github_access_token} | pass insert -m "infrastructure/${DOMAIN}/github_access_token_ro"
}

function task_set_cloud_api_token {
  echo "Enter the Hetzner Cloud API token, followed by [ENTER]:"
  read -r hetzner_cloud_api_token
  echo ${hetzner_cloud_api_token} | pass insert -m "infrastructure/${DOMAIN}/cloud_api_token"
}

function task_set_dns_api_token {
  echo "Enter the Hetzner DNS API token, followed by [ENTER]:"
  read -r hetzner_dns_api_token
  echo ${hetzner_dns_api_token} | pass insert -m "infrastructure/${DOMAIN}/dns_api_token"
}

ARG=${1:-}
shift || true
case ${ARG} in
  build) task_build "$@" ;;
  run) task_run "$@" ;;
  test) task_test "$@" ;;
  deploy) task_deploy "$@" ;;
  deploy-html) task_deploy_html "$@" ;;
  output) task_output "$@" ;;
  infra-instance) task_infra_instance "$@" ;;
  infra-storage) task_infra_storage "$@" ;;
  ssh-instance) task_ssh_instance "$@" ;;
  generate-ssh-identities) task_generate_ssh_identities ;;
  generate-deploy-ssh-identity) generate_deploy_ssh_identity ;;
  set-github-access-token-rw) task_set_github_access_token_rw ;;
  set-github-access-token-ro) task_set_github_access_token_ro ;;
  set-cloud-api-token) task_set_cloud_api_token ;;
  set-dns-api-token) task_set_dns_api_token ;;
  docker-login) task_docker_login ;;
  *) task_usage ;;
esac
