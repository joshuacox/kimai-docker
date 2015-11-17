.PHONY: all help build run builddocker rundocker kill rm-image rm clean enter logs

user = $(shell whoami)
ifeq ($(user),root)
$(error  "do not run as root! run 'gpasswd -a USER docker' on the user of your choice")
endif

all: help

help:
	@echo ""
	@echo "-- Help Menu"
	@echo ""  This is merely a base image for usage read the README file
	@echo ""   1. make run       - build and run docker container
	@echo ""   2. make build     - build docker container
	@echo ""   3. make clean     - kill and remove docker container
	@echo ""   4. make enter     - execute an interactive bash in docker container
	@echo ""   3. make logs      - follow the logs of docker container

build: NAME TAG builddocker

run: MYSQL_PASS rm build mysqlbare rundocker

prod: MYSQL_DATADIR MYSQL_PASS rm build mysqlcid runprod

## useful hints
## specifiy ports
#-p 44180:80 \
#-p 27005:27005/udp \
## link another container
#--link some-mysql:mysql \
## assign environmant variables
#--env STEAM_USERNAME=`cat steam_username` \
#--env STEAM_PASSWORD=`cat steam_password` \

# change uid in the container for easy dev work
# first you need to determin your user:
# $(eval UID := $(shell id -u))
# then you need to insert this as a env var:
# -e "DOCKER_UID=$(UID)" \
# then look at chguid.sh for an example of 
# what needs to be run in the live container upon startup

rundocker:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	chmod 777 $(TMP)
	@docker run --name=$(NAME) \
	--cidfile="cid" \
	-v $(TMP):/tmp \
	-d \
	-P \
	--link `cat NAME`-mysqlbare:mysql \
	-v /var/run/docker.sock:/run/docker.sock \
	-v $(shell which docker):/bin/docker \
	-t $(TAG)

runprod:
	$(eval TMP := $(shell mktemp -d --suffix=DOCKERTMP))
	$(eval NAME := $(shell cat NAME))
	$(eval TAG := $(shell cat TAG))
	chmod 777 $(TMP)
	@docker run --name=$(NAME) \
	--cidfile="cid" \
	-v $(TMP):/tmp \
	-d \
	-P \
	--link `cat NAME`-mysql:mysql \
	-v /var/run/docker.sock:/run/docker.sock \
	-v `cat APACHE_DATADIR`:/var/www/html \
	-v $(shell which docker):/bin/docker \
	-t $(TAG)

grab:
	-mkdir -p datadir
	docker cp `cat cid`:/var/www/html datadir/
	docker cp `cat mysqlbare`:/var/lib/mysql datadir/
	-rm -Rf datadir/html/installer
	sudo chown -R www-data. datadir/html
	sudo chown -R bob. datadir/mysql
	echo `pwd`/datadir/mysql > MYSQL_DATADIR
	echo `pwd`/datadir/html > APACHE_DATADIR

builddocker:
	/usr/bin/time -v docker build -t `cat TAG` .

kill:
	-@docker kill `cat cid`

mysqlbare:
	docker run \
	--cidfile="mysqlbare" \
	--name `cat NAME`-mysqlbare \
	-e MYSQL_ROOT_PASSWORD=`cat MYSQL_PASS` \
	-d \
	mysql:5.5

mysqlcid:
	docker run \
	--cidfile="mysqlcid" \
	--name `cat NAME`-mysql \
	-e MYSQL_ROOT_PASSWORD=`cat MYSQL_PASS` \
	-d \
	-v `cat MYSQL_DATADIR`:/var/lib/mysql \
	mysql:5.5

rm-image:
	-@docker rm `cat cid`
	-@rm cid

rm: kill rm-image

rmmysql: mysqlcid-rmkill

mysqlcid-rmkill:
	-@docker kill `cat mysqlcid`
	-@docker rm `cat mysqlcid`
	-@rm mysqlcid

rmbare: mysqlbare-rmkill

mysqlbare-rmkill:
	-@docker kill `cat mysqlbare`
	-@docker rm `cat mysqlbare`
	-@rm mysqlbare

clean: rm rmbare rmmysql

enter:
	docker exec -i -t `cat cid` /bin/bash

logs:
	docker logs -f `cat cid`

NAME:
	@while [ -z "$$NAME" ]; do \
		read -r -p "Enter the name you wish to associate with this container [NAME]: " NAME; echo "$$NAME">>NAME; cat NAME; \
	done ;

TAG:
	@while [ -z "$$TAG" ]; do \
		read -r -p "Enter the tag you wish to associate with this container [TAG]: " TAG; echo "$$TAG">>TAG; cat TAG; \
	done ;

APACHE_DATADIR:
	@while [ -z "$$APACHE_DATADIR" ]; do \
		read -r -p "Enter the tag you wish to associate with this container [APACHE_DATADIR]: " APACHE_DATADIR; echo "$$APACHE_DATADIR">>APACHE_DATADIR; cat APACHE_DATADIR; \
	done ;

MYSQL_DATADIR:
	@while [ -z "$$MYSQL_DATADIR" ]; do \
		read -r -p "Enter the tag you wish to associate with this container [MYSQL_DATADIR]: " MYSQL_DATADIR; echo "$$MYSQL_DATADIR">>MYSQL_DATADIR; cat MYSQL_DATADIR; \
	done ;

MYSQL_PASS:
	@while [ -z "$$MYSQL_PASS" ]; do \
		read -r -p "Enter the tag you wish to associate with this container [MYSQL_PASS]: " MYSQL_PASS; echo "$$MYSQL_PASS">>MYSQL_PASS; cat MYSQL_PASS; \
	done ;


