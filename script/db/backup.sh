#!/bin/bash
set -euo pipefail

this_dir="$(dirname -- "$(readlink -f -- "$0")")"
repo_dir="$(readlink -f -- "$this_dir/../..")"
util_dir="$repo_dir/script/util"
docker_dir="$repo_dir/docker"

# shellcheck source=script/util/couchdb.sh
. "$util_dir/couchdb.sh"

compose_env

service_db=db
service_db_backup=db-backup

echo -n "Enter CouchDB password for $COUCHDB_USER@$service_db: "
read -rs pass
echo

compose up \
	--build \
	--detach \
	--remove-orphans \
	"$service_db" \
	"$service_db_backup"

db_await_up "$service_db_backup"

tok="$(db_login_token "$service_db" "$COUCHDB_USER" "$pass")"

url_origin="http://$COUCHDB_USER:$pass@$service_db:$DB_PORT_INTERNAL/$DB_NAME"
url_backup="http://$COUCHDB_USER:$COUCHDB_PASSWORD@$service_db_backup:$DB_PORT_INTERNAL/$DB_NAME"

# Replicate from original to temp before copying from temp to deterministically
# snapshot the DB state without stopping the DB container.
# https://docs.couchdb.org/en/stable/api/server/common.html#replicate
db_request "$service_db" POST _replicate "$tok" \
	--header "Content-Type: application/json" \
	--data '{
	"source": "'"$url_origin"'",
	"target": "'"$url_backup"'",
	"create_target": true,
	"continuous": false
}'
