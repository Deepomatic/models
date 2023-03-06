ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

all: build-base
	docker run -v ${ROOT_DIR}:/app -w /app -ti tf-models bash

# Bump requirements
bump: build-base
	docker run -v ${ROOT_DIR}:/app -w /app -ti tf-models pip-compile -v requirements.in

build-base:
	docker build -t tf-models --target base .

build:
	docker build -t tf-models .
