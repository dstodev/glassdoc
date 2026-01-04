FROM ubuntu:noble

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install --yes \
	curl \
	iputils-ping \
	jq \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get clean
