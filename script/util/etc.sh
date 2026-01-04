# shellcheck shell=bash

# :: etc.sh ------------------------------------------
#
# Source this file with Bash for general utilities.
#
# ----------------------------------------------------

# -- Status constants

# When terminated by signals, programs return status-code=128+SIGNAL_NUMBER.
#
# `kill -l`      lists signal names
# `kill -l NAME` lists signal number for each name
STATUS_SIGINT=$((128 + $(kill -l INT)))

# -- String constants

TAB=$'\t' # or "$(printf '\t')"

# -- Bash assertion

# Print an error message and exit if the file calling this function is not
# itself sourced, and by Bash.
#
# To include this function, source this file from a SOURCED Bash script such as
# this and others in this util/ directory by path relative to the sourced script
# like:
#
#   #!/bin/bash
#   . "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/etc.sh"
#   assert_bash_sourced_this_file
#
assert_bash_sourced_this_file() {
	local name
	if ! bash_sourced_this_file; then
		name="$(basename -- "$0")"
		if cmd_exists realpath && [ -n "${BASH_SOURCE-}" ]; then
			# repo_root requires BASH_SOURCE
			name="$(realpath --relative-to="$(repo_root)" -- "$0")"
		fi
		cat <<-EOF >&2

			!! Error:
			${TAB}You must source $name with Bash:

			${TAB}#!/bin/bash
			${TAB}. $name

		EOF
		exit 1
	fi
}

# Return 0 if BASH_SOURCE is available & this file was sourced by another.
bash_sourced_this_file() {
	[ -n "${BASH_SOURCE-}" ] &&
		print_source_origin >/dev/null
}

# Print the canonical path of the file that calls print_source_origin(), then
# return
# 0. If not sourced, instead print nothing then return 1.
#
# Implemented by printing the canonical path of the file that sources the file
# containing this function definition.
#
# Requires Bash for BASH_SOURCE and FUNCNAME arrays.
print_source_origin() {
	local i name
	i=0
	while [ "$i" -lt "${#BASH_SOURCE[@]}" ]; do
		name="${FUNCNAME[$i]}"
		# break if we reach the main script before finding a source origin
		[ "$name" = 'main' ] && return 1
		i=$((i + 1))
		[ "$name" = 'source' ] && break # keep break after adding i+1;
		# if FUNCNAME[i]="source", BASH_SOURCE[i+1]=the source "origin"
		# see: https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-BASH_005fSOURCE
		# and: https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html#index-FUNCNAME
	done
	readlink -f -- "${BASH_SOURCE[$i]}"
}

assert_bash_sourced_this_file

# -- Utility functions

cmd_exists() {
	while [ "$#" -gt 0 ]; do
		if ! command -v "$1" >/dev/null 2>&1; then
			return 1
		fi
		shift
	done
}

host_ip() {
	ip route get 1 | awk '{ print $7; exit }'
}

repo_root() {
	local dir
	# ${BASH_SOURCE[0]} in a function from a sourced file contains the path to
	# the file that defines the function.
	dir="$(readlink -f -- "$(dirname -- "${BASH_SOURCE[0]}")/../..")"
	if [ -d "$dir/.git" ]; then
		echo "$dir"
	else
		return 1
	fi
}

print_list() {
	local last_index width i
	last_index=$(($# - 1))
	width="${#last_index}"
	i=0
	while [ "$#" -gt 0 ]; do
		printf "[%0${width}d]=%s\n" "$i" "$1"
		i=$((i + 1))
		shift
	done
}

# Read file with path "$1" and print its Bash-interpreted contents.
#
# For each line:
# 1. Capture the Bash-evaluated line as-printed-by printf from a subshell.
# 2. Print the evaluated line.
# 3. Evaluate the line within the function's subshell to preserve side-effects
#    such as variable assignments for subsequent lines.
print_bash_interpreted_file() {
	local in_file
	in_file="$1"
	if [ ! -f "$in_file" ]; then
		return 1
	fi
	# || [ -n "$line" ] handles files without trailing newline; they would
	#    otherwise have their last line skipped.
	(
		while IFS='' read -r line || [ -n "$line" ]; do
			result="$(eval "printf '%s\n' \"$line\"")"
			echo "$result"
			eval "$result"
		done <"$in_file"
	)
}

prompt_user_password() {
	local user="${1-}"
	local addtl_prompt

	if [ -n "$user" ]; then
		addtl_prompt=" for user $user"
	fi

	local entry=a confirm=b
	while [ "$entry" != "$confirm" ]; do
		echo -n "Enter password$addtl_prompt: " >&2
		read -rs entry
		echo >&2
		echo -n "Confirm password$addtl_prompt: " >&2
		read -rs confirm
		echo >&2
		if [ "$entry" != "$confirm" ]; then
			echo 'Entered passwords do not match!' >&2
			echo >&2
		fi
	done
	echo "$entry"
}
