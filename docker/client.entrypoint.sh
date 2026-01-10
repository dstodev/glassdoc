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
printf -- '- workdir: %s\n' "$(pwd)"

export DBUS_SYSTEM_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket

eval "$(dbus-launch --sh-syntax)"
export DBUS_SESSION_BUS_ADDRESS
export DBUS_SESSION_BUS_PID

BG_SERVICE_PIDS=()
start_bg_service() {
	local cmd="$1"
	shift
	local log_dir="$HOME/service-logs"
	local log_pfx="$log_dir/$cmd"
	mkdir -p "$log_dir"
	if ! pgrep --exact "$cmd" >/dev/null; then
		echo "$cmd $*"
		"$cmd" "$@" >"$log_pfx.out.log" 2>"$log_pfx.err.log" &
		pid=$!
		ps -p "$pid"
		BG_SERVICE_PIDS+=("$pid")
	fi
}

# Create virtual framebuffer
start_bg_service Xvfb "$DISPLAY" \
	-nolisten tcp \
	-nolisten unix \
	-screen 0 "$WEBVIEW_RESOLUTION"

# Start X11 window manager
start_bg_service openbox

# Start VNC server to share X11 display
start_bg_service x11vnc \
	-display "WAIT$DISPLAY" \
	-forever \
	-listen localhost \
	-nopw \
	-rfbport "$WEBVIEW_PORT_X11VNC_INTERNAL"
#	removed `-ncache 10` because it causes weird screen duplication

# Start Obsidian application
start_bg_service obsidian \
	--no-sandbox \
	--disable-gpu \
	--use-gl=swiftshader

# Start websockify to provide noVNC access to VNC server over HTTP
start_bg_service websockify \
	--web=/usr/share/novnc/ \
	"$WEBVIEW_PORT_HTTP_INTERNAL" "localhost:$WEBVIEW_PORT_X11VNC_INTERNAL"

# Set up environment
# TODO: Mount with Docker to host
#mkdir -p "$HOME/vault"

# Set "desktop" background color
xsetroot -solid gray

for svc_pid in "${BG_SERVICE_PIDS[@]}"; do
	echo "- Awaiting process exit: $svc_pid"
	wait "$svc_pid"
done
