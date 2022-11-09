# Makefile.  Generated from Makefile.in by configure.

# Copyright (C) 1994-2020 Free Software Foundation, Inc.

# This Makefile.in is free software; the Free Software Foundation
# gives unlimited permission to copy and/or distribute it,
# with or without modifications, as long as this notice is preserved.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, to the extent permitted by law; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE.

CONFIG = .version
include ${CONFIG}

rpmbuild:
	docker build -t rpmbuild -f Dockerfile.centos9 . 

debuild:
	docker build -t debuild -f Dockerfile.debian . 

patch:
	git aftermerge patch

minor:
	git aftermerge minor

major:
	git aftermerge major

dist-gzip:
	mkdir -p dist/${APPNAME}-${VERSION}/
	cp vols.sh dist/${APPNAME}-${VERSION}/
	cd dist && tar cvzf ${APPNAME}-${VERSION}.tar.gz ${APPNAME}-${VERSION} && rm -rf ${APPNAME}-${VERSION}

clean:
	-rm -rf dist

up:
	docker-compose up

down:
	docker-compose down

destroy:
	-docker rmi rpmbuild
	-docker rmi debuild

rpmexec:
	docker exec -it volsh_centos9_1 /usr/bin/bash

debexec:
	docker exec -it volsh_debian_1 /bin/bash
