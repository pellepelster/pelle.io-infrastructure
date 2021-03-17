#!/usr/bin/env bash

set -o pipefail -o errexit -o nounset

gomplate --file /invoice-ninja/templates/.env.tpl > /invoice-ninja/ninja/.env

exec /usr/bin/supervisord -n -c /invoice-ninja/config/supervisord.conf