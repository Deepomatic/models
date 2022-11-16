ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

all:
	docker build -t tf-models --target base .
	docker run -v ${ROOT_DIR}/research:/app -w /app -ti tf-models bash
