#!/usr/bin/env bash

set -o pipefail -o errexit -o nounset

gomplate --file /www/templates/nginx.conf.tpl > /www/config/nginx.conf

nginx -c /www/config/nginx.conf