#!/bin/bash
set -euo pipefail

# Open a public route to the CouchDB instance

this_dir="$(dirname -- "$(readlink -f -- "$0")")"

# shellcheck source=script/util/compose.sh
. "$this_dir/../util/compose.sh"

service='db-route'

compose build "$service"
compose up --detach --remove-orphans "$service"

announce() { (
	compose_env
	echo "CouchDB accessible: http://$(host_ip):$DB_PORT_HOST_USER/_utils"
); }
announce
