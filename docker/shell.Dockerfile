FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
	curl \
	iputils-ping \
	jq \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get clean
