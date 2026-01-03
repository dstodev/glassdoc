#!/bin/bash
set -euo pipefail

# requires `jq` command;

this_dir="$(dirname -- "$(readlink -f -- "$0")")"
repo_dir="$(readlink -f -- "$this_dir/../..")"
util_dir="$repo_dir/script/util"
docker_dir="$repo_dir/docker"

# shellcheck source=script/util/couchdb.sh
. "$util_dir/couchdb.sh"

compose_env

db_await_up db

# -- Set up single-node cluster
# https://docs.couchdb.org/en/stable/setup/single-node.html
# https://docs.couchdb.org/en/stable/api/server/common.html#post--_cluster_setup
# e.g.: POST /_cluster_setup

setup_payload="$(
	cat <<-EOF
		{
			"action": "enable_single_node",
			"bind_address": "0.0.0.0",
			"username": "$COUCHDB_USER",
			"password": "$COUCHDB_PASSWORD",
			"port": $DB_PORT_INTERNAL
		}
	EOF
)"
db_request_with_credential db POST _cluster_setup "$COUCHDB_USER:$COUCHDB_PASSWORD" \
	--header 'Content-Type: application/json' \
	--data "$setup_payload"

# -- Set up admin user

tok="$(db_login_token db "$COUCHDB_USER" "$COUCHDB_PASSWORD")"
db_try_token db "$tok"

tok="$(db_set_admin_password db "$tok")"

# Create obsidiandb database
# https://docs.couchdb.org/en/stable/api/database/common.html#put--db
# e.g.: PUT /{db}

db_request db PUT "$DB_NAME?partitioned=false" "$tok"

# Add options from guide
# https://docs.couchdb.org/en/stable/api/server/configuration.html#put--_node-node-name-_config-section-key
# e.g.: PUT /_node/{node-name}/_config/{section}/{key}

node_name="$(db_request db GET _membership "$tok" | jq -r '.all_nodes[0]')"
node_config="_node/$node_name/_config"

db_request db PUT "$node_config/httpd/require_valid_user" "$tok" \
	--header 'Content-Type: application/json' \
	--data '"true"'

db_request db PUT "$node_config/chttpd/require_valid_user" "$tok" \
	--header 'Content-Type: application/json' \
	--data '"true"'

db_request db PUT "$node_config/chttpd_auth/require_valid_user" "$tok" \
	--header 'Content-Type: application/json' \
	--data '"true"'

db_request db PUT "$node_config/httpd/WWW-Authenticate" "$tok" \
	--header 'Content-Type: application/json' \
	--data '"Basic realm=\"CouchDB\""'

db_request db PUT "$node_config/httpd/enable_cors" "$tok" \
	--header 'Content-Type: application/json' \
	--data '"true"'

db_request db PUT "$node_config/chttpd/enable_cors" "$tok" \
	--header 'Content-Type: application/json' \
	--data '"true"'

db_request db PUT "$node_config/chttpd/max_http_request_size" "$tok" \
	--header 'Content-Type: application/json' \
	--data '"4294967296"' # 4 GB; 2^30 * 4

db_request db PUT "$node_config/couchdb/max_document_size" "$tok" \
	--header 'Content-Type: application/json' \
	--data '"50000000"'

db_request db PUT "$node_config/cors/credentials" "$tok" \
	--header 'Content-Type: application/json' \
	--data '"true"'

db_request db PUT "$node_config/cors/origins" "$tok" \
	--header 'Content-Type: application/json' \
	--data '"app://obsidian.md,capacitor://localhost,http://localhost"'
