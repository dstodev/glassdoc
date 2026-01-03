#!/bin/bash
set -euo pipefail

# Open a public route to the CouchDB instance

this_dir="$(dirname -- "$(readlink -f -- "$0")")"

# shellcheck source=script/util/compose.sh
. "$this_dir/util/compose.sh"

compose up --build --detach --remove-orphans db-route

announce() {
	local host
	host="$(ip route get 1 | awk '{ print $7; exit }')"
	(
		compose_env
		echo "CouchDB accessible: http://$host:$DB_PORT_HOST_USER/_utils"
	)
}
announce
