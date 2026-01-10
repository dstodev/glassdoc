FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install --yes \
	# basic dependencies
	ca-certificates \
	curl \
	tini \
	wget \
	\
	# required to host web view, suppress warnings, etc.
	dbus \
	dbus-x11 \
	dconf-service \
	libgbm1 \
	libgtk-3-0 \
	libnss3 \
	libxdamage1 \
	libxrandr2 \
	libxss1 \
	novnc \
	openbox \
	websockify \
	x11vnc \
	xvfb \
	\
	# required for obsidian .deb below
	libappindicator3-1 \
	libasound2t64 \
	libnotify4 \
	libsecret-1-0 \
	xdg-utils

RUN apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /opt/obsidian
RUN wget https://github.com/obsidianmd/obsidian-releases/releases/download/v1.10.6/obsidian_1.10.6_amd64.deb \
	&& apt-get install --yes ./obsidian_1.10.6_amd64.deb

WORKDIR /home/ubuntu
ENV DISPLAY=:0

COPY --chown=ubuntu:ubuntu client.entrypoint.sh client.entrypoint.sh

ENTRYPOINT ["tini", "--", "./client.entrypoint.sh"]
