# shellcheck shell=bash

# :: compose.sh --------------------------------------------
#
# Source this file with Bash for Docker Compose helpers.
#
# ----------------------------------------------------------

# shellcheck source=script/util/etc.sh
. "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/etc.sh"
assert_bash_sourced_this_file

# Run `docker compose "$@"` within directory docker/.
compose() {
	local this_dir repo_dir docker_dir
	this_dir="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
	repo_dir="$(readlink -f -- "$this_dir/../..")"
	util_dir="$repo_dir/script/util"
	docker_dir="$repo_dir/docker"
	(
		# shellcheck source=script/util/b64.sh
		. "$util_dir/b64.sh" # for b64url_mkrandom used by docker/in.env
		compose_env
		cd "$docker_dir" || return 1
		# explicit --env-file to force an error if .env file is missing
		docker compose --env-file "$docker_dir/.env" "$@"
	)
}

# Source docker/.env into the current shell's environment.
#
# Creates docker/.env only if missing, from docker/in.env.
compose_env() {
	local this_dir repo_dir docker_dir
	this_dir="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
	repo_dir="$(readlink -f -- "$this_dir/../..")"
	docker_dir="$repo_dir/docker"
	env_file="$docker_dir/.env"

	[ -f "$env_file" ] || _interpolate_env_in | _snip >"$env_file"

	# shellcheck source=docker/in.env
	. "$env_file"
}

_snip() {
	sed '/^#[[:space:]]*+snip/,/^#[[:space:]]*-snip/d' |
		cat --squeeze-blank
}

_interpolate_env_in() {
	local this_dir repo_dir docker_dir
	this_dir="$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"
	repo_dir="$(readlink -f -- "$this_dir/../..")"
	docker_dir="$repo_dir/docker"
	(
		umask 0377 # u=r,go=
		print_bash_interpreted_file "$docker_dir/in.env"
	)
}
