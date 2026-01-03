MAKEFLAGS += --no-print-directory

# List project containers
ps:
	script/compose-shim.sh ps | \
	less --squeeze-blank-lines
.PHONY: ps

# Start the CouchDB service
db:
	script/db/start.sh
.PHONY: db

# Backup the database
backup:
	script/db/backup.sh
.PHONY: backup

# Stop all db services
stop down:
	script/db/stop.sh
.PHONY: stop down

# Start routing traffic to CouchDB
open:
	script/open.sh
.PHONY: open

# Stop routing traffic to CouchDB
close:
	script/close.sh
.PHONY: close

# Start the database and open route
up: db open
.PHONY: up

# Create the database and populate bare-minimum data
init:
	$(MAKE) db
	script/db/init-obsidiandb.sh
	$(MAKE) open
.PHONY: init

# Purge the database by stopping all containers and removing project volumes
# This deletes all data in the database!
danger-purge-database:
	$(MAKE) stop
	script/compose-shim.sh down \
		--remove-orphans \
		--volumes
	rm -f docker/.env
.PHONY: danger-purge-database

danger-shell-db:
	script/compose-shim.sh exec db bash
.PHONY: danger-shell-db

sh shell:
	script/compose-shim.sh build shell
	script/compose-shim.sh run \
		--rm \
		--remove-orphans \
		shell
.PHONY: sh shell
