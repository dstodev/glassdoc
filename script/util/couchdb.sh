# shellcheck shell=bash

# :: couchdb.sh ------------------------------------
#
# Source this file with Bash for CouchDB helpers.
#
# --------------------------------------------------

# shellcheck source=script/util/compose.sh
. "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/compose.sh"

assert_bash_sourced_this_file

db_request() {
	local service="$1"
	local method="$2"
	local path="$3"
	local token="$4"
	shift 4
	local cookies=()
	if [ -n "$token" ]; then
		cookies+=(--cookie "$token")
	fi
	(
		compose_env
		url="http://$service:$DB_PORT_INTERNAL/$path"
		_db_curl --request "$method" "${cookies[@]}" "$url" "$@"
	)
}

db_request_with_credential() {
	local service="$1"
	local method="$2"
	local path="$3"
	local credential="$4"
	shift 4
	db_request "$credential@$service" "$method" "$path" '' "$@"
}

db_login_token() {
	local service="$1"
	local user="$2"
	local pass="$3"
	shift 3
	(
		compose_env
		umask 0377
		_db_curl \
			--request POST \
			"http://$service:$DB_PORT_INTERNAL/_session" \
			--header 'Content-Type: application/json' \
			--data '{
				"name": "'"$user"'",
				"password": "'"$pass"'"
			}' \
			--dump-header - |
			grep 'Set-Cookie:' | sed -E 's/Set-Cookie: ([^;]+);.*/\1/'
	)
}

db_try_token() {
	local service="$1"
	local cookie="$2"
	shift 2
	(
		compose_env
		_db_curl \
			--request GET \
			--cookie "$cookie" \
			"http://$service:$DB_PORT_INTERNAL/_session"
	)
}

_db_curl() {
	compose run --rm shell curl \
		--retry 5 \
		--retry-connrefused \
		--retry-delay 2 \
		--silent \
		"$@"
}

db_await_up() {
	local service="$1"
	shift
	printf 'waiting for %s... ' "$service"
	local response status=0
	# https://docs.couchdb.org/en/stable/api/server/common.html#up
	response="$(db_request "$service" GET _up '')" || status=$?
	if [ "$status" -eq 0 ]; then
		echo 'ok'
	else
		echo 'failed'
	fi
	echo "$response"
	return "$status"
}

db_set_admin_password() {
	local db="$1"
	local token="$2"
	shift 2
	(
		compose_env
		pass="$(prompt_user_password "$COUCHDB_USER")"
		db_request "$db" PUT "_node/_local/_config/admins/$COUCHDB_USER" "$token" \
			--header 'Content-Type: application/json' \
			--data "\"$pass\"" >/dev/null
		db_login_token "$db" "$COUCHDB_USER" "$pass"
	)
}
