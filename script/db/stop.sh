#!/bin/bash
set -euo pipefail

this_dir="$(dirname -- "$(readlink -f -- "$0")")"
repo_dir="$(readlink -f -- "$this_dir/../..")"
util_dir="$repo_dir/script/util"

# shellcheck source=script/util/compose.sh
. "$util_dir/compose.sh"

compose down --remove-orphans db-route db
