# This Makefile is based on the Makefile defined in the Python Best Practices repository:
# https://git.datapunt.amsterdam.nl/Datapunt/python-best-practices/blob/master/dependency_management/
.PHONY: app
dc = docker-compose

help:                               ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

requirements:
	$(dc) run --rm server bash ./upgrade_cantaloupe_version.sh

build:
	$(dc) build

push:
	$(dc) push

app:
	$(dc) up server

test:
	$(dc) run --rm tester $(ARGS)

clean:
	$(dc) down -v

bash:
	$(dc) run --rm server bash
