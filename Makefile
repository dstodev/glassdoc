MAKEFLAGS += --no-print-directory

# List project containers
ps:
	script/compose-shim.sh ps --all | cat
.PHONY: ps

# Create the database and populate bare-minimum data
init:
	$(MAKE) stop start
	script/db/init.sh
	$(MAKE) client
.PHONY: init

# Start the CouchDB service
start:
	script/db/start.sh
.PHONY: start

# Start a web-accessible Obsidian client
client:
	script/client.sh
.PHONY: client

client-log:
	script/compose-shim.sh logs --follow client
.PHONY: client-log

client-job-logs:
	script/compose-shim.sh exec client bash -c 'tail --lines +1 service-logs/*.log'
	script/compose-shim.sh logs client
.PHONY: client-job-logs

client-shell:
	script/compose-shim.sh exec client bash
.PHONY: client-shell
# Stop all db services
stop:
	script/db/stop.sh
.PHONY: stop

# Replicate then backup the database's data
backup:
	script/db/backup.sh
.PHONY: backup

# Open a shell in an isolated container but connected to the db network
sh shell:
	script/compose-shim.sh build shell
	script/compose-shim.sh run \
		--rm \
		--remove-orphans \
		shell
.PHONY: sh shell

# Open public route to CouchDB
open:
	script/db/open.sh
.PHONY: open

# Close public route to CouchDB
close:
	script/db/close.sh
.PHONY: close

# Purge the database by stopping all containers and removing project volumes
# This deletes all data in the database!
danger-purge-database:
	$(MAKE) stop
	script/compose-shim.sh down \
		--remove-orphans \
		--volumes
	rm -f docker/.env
.PHONY: danger-purge-database

# Open a shell inside the live database container
danger-shell-db:
	script/compose-shim.sh exec db bash
.PHONY: danger-shell-db
