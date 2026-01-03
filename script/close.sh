#!/bin/bash
set -euo pipefail

# Close public routes to the CouchDB instance

this_dir="$(dirname -- "$(readlink -f -- "$0")")"

# shellcheck source=script/util/compose.sh
. "$this_dir/util/compose.sh"

compose stop db-route
