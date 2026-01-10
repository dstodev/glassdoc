#!/bin/bash
set -euo pipefail

this_dir="$(dirname -- "$(readlink -f -- "$0")")"
repo_dir="$(readlink -f -- "$this_dir/../..")"
util_dir="$repo_dir/script/util"
docker_dir="$repo_dir/docker"

# shellcheck source=script/util/couchdb.sh
. "$util_dir/couchdb.sh"

service_db='db'
service_db_backup='db-backup'

compose_env

echo -n "Enter CouchDB password for $COUCHDB_USER@$service_db: "
read -rs pass
echo

compose build "$service_db_backup"
compose up \
	--detach \
	--remove-orphans \
	"$service_db" \
	"$service_db_backup"

db_await_up "$service_db_backup"

cleanup() {
	compose down --remove-orphans "$service_db_backup"
}
trap cleanup EXIT

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

# TODO: After replicate to backup db, copy data from the backup db container to
# dir backup/ with name format: glassdoc-backup_YYYY-MM-DD_HH-MM-SS_TZ.tar.gz
