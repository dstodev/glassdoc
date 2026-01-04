#!/bin/bash
set -euo pipefail

this_dir="$(dirname -- "$(readlink -f -- "$0")")"
repo_dir="$(readlink -f -- "$this_dir/..")"
util_dir="$repo_dir/script/util"

# shellcheck source=script/util/compose.sh
. "$util_dir/compose.sh"

service='obsidian-webclient'

compose down --remove-orphans "$service"
compose build "$service" >/dev/null
compose up \
	--detach \
	--remove-orphans \
	"$service"

announce() { (
	compose_env
	echo "Web client available: http://$(host_ip):$WEBVIEW_PORT_HOST_USER/vnc.html"
); }
announce
