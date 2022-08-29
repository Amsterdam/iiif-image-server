# This Makefile is based on the Makefile defined in the Python Best Practices repository:
# https://git.datapunt.amsterdam.nl/Datapunt/python-best-practices/blob/master/dependency_management/
.PHONY: app
dc = docker-compose

help:                               ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

upgrade:
	# Get the current major version from the Dockerfile
	VERSION=`grep "ENV CANTALOUPE_VERSION" Dockerfile | cut -d'"' -f 2`
	MAJOR_VERSION=`echo $VERSION | cut -d. -f1`

	# Get the latest version within this major version from the Cantaloupe repo tags
	REPO_VERSION=`git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags git@github.com:cantaloupe-project/cantaloupe.git '*.*.*' \
    | grep v${MAJOR_VERSION} \
    | tail --lines=1 \
    | cut --delimiter='/' --fields=3 \
    | sed 's/v//'`

	# Upgrade the version in the Dockerfile if needed
    if [ "$VERSION" = "$REPO_VERSION" ]; then
		echo -e "\n ### The current ${VERSION} is the latest version. No Upgrade needed. ### \n"
	else
		sed -i "s/${VERSION}/${REPO_VERSION}/" Dockerfile
		echo -e "\n ### Upgraded Dockerfile from v$VERSION to v$REPO_VERSION ### \n"
	fi

	# Check if there is a new major version
	NEWEWST_VERSION=`git -c 'versionsort.suffix=-' \
    ls-remote --exit-code --refs --sort='version:refname' --tags git@github.com:cantaloupe-project/cantaloupe.git '*.*.*' \
    | grep v$((MAJOR_VERSION+1)) \
    | tail --lines=1 \
    | cut --delimiter='/' --fields=3 \
    | sed 's/v//'`
    NEWEST_MAJOR_VERSION=`echo $NEWEWST_VERSION | cut -d. -f1`

    if [ "$NEWEST_MAJOR_VERSION" != "$MAJOR_VERSION" ]; then
		echo -e "\n ### There is a new major version ${NEWEST_MAJOR_VERSION} out: ${NEWEWST_VERSION}. Consider upgrading. ### \n"
	fi

build:
	$(dc) build

push: build
	$(dc) push

app:
	$(dc) up server

test:
	$(dc) run --rm tester $(ARGS)

clean:
	$(dc) down -v

bash:
	$(dc) run --rm server bash
