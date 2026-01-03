# shellcheck shell=bash

# :: b64.sh ---------------------------------------------
#
# Source this file with Bash for various Base64 tools.
#
# -------------------------------------------------------

# shellcheck source=script/util/etc.sh
. "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")/etc.sh"
assert_bash_sourced_this_file

b64url_mkrandom() {
	local length="${1-32}"
	local entropy='/dev/urandom'

	base64 "$entropy" |
		head --bytes "$length" |
		LC_ALL=C tr '+/' '-_' || # Base64 -> Base64URL
		# Suppress SIGPIPE from base64 when head closes, and print newline
		echo
}
