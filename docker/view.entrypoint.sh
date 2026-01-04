#!/bin/bash
set -euo pipefail

if [ "$(id --user)" -eq 0 ]; then
	echo "! Starting dbus-daemon"
	mkdir -p /run/dbus
	dbus-daemon --system --fork
	cd "$(dirname -- "$0")"
	exec su ubuntu -c "$0" "$@"
fi

echo "! Starting Obsidian web client"
pwd

export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket

eval "$(dbus-launch --sh-syntax)"
export DBUS_SESSION_BUS_ADDRESS
export DBUS_SESSION_BUS_PID

start_bg_service() {
	local cmd="$1"
	shift
	local log_dir="$HOME/service-logs"
	local log_pfx="$log_dir/$cmd"
	mkdir -p "$log_dir"
	if ! pgrep --exact "$cmd" >/dev/null; then
		echo "$cmd $*" >&2
		"$cmd" "$@" >"$log_pfx.out.log" 2>"$log_pfx.err.log" &
		pid=$!
		ps -p "$pid" >&2
	fi
	LAST_PID=$pid
}

services=()
start_bg_service Xvfb "$DISPLAY" \
	-nolisten tcp \
	-nolisten unix \
	-screen 0 1920x1080x24
services+=("$LAST_PID")

start_bg_service openbox
services+=("$LAST_PID")

start_bg_service x11vnc \
	-display "WAIT$DISPLAY" \
	-forever \
	-listen localhost \
	-ncache 10 \
	-nopw \
	-rfbport 5900
services+=("$LAST_PID")

start_bg_service obsidian \
	--enable-unsafe-swiftshader \
	--no-sandbox
services+=("$LAST_PID")
start_bg_service websockify \
	--web=/usr/share/novnc/ \
	8080 localhost:5900
services+=("$LAST_PID")

mkdir -p "$HOME/vault"

for svc_pid in "${services[@]}"; do
	echo "- Awaiting process exit: $svc_pid"
	wait "$svc_pid"
done
