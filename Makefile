BASEDIR = $(shell pwd)
PORT_DB=3306
APPNAME=todo

dev: build
	docker run --name $(APPNAME) -dt -v $(BASEDIR)/code/todo:/app/todo -p 8500:8500 \
	-v /Users/tpryan/.config/gcloud/:/creds -e GOOGLE_APPLICATION_CREDENTIALS=/creds/application_default_credentials.json \
	-e installModules=orm,debugger,mysql,redissessionstorage -e acceptEULA=YES -e password=ColdFusion123 \
	-e DB_USER=todo_user -e DB_PASS=todo_pass -e DB_HOST=host.docker.internal \
	-e DB_NAME=todo -e DB_PORT=3306 \
	$(APPNAME)

build: clean
	docker build  -t $(APPNAME) .

clean:
	-docker stop $(APPNAME)
	-docker rm $(APPNAME)	

db: cleandb
	cd database && docker build -t todo-mysql .
	docker run --name todo-mysql -p $(PORT_DB):$(PORT_DB) \
	-e MYSQL_ROOT_PASSWORD=password -e MYSQL_ROOT_HOST=% -d todo-mysql	

cleandb:
	-docker stop todo-mysql
	-docker rm todo-mysql

all: db redis dev	

services: 
	gcloud services enable cloudbuild.googleapis.com -q 

cloudbuild:
	gcloud builds submit .


redis: cleanredis
	docker run --name todo-redis -p 6379:6379 -d redis	

cleanredis:
	-docker stop todo-redis
	-docker rm todo-redis	