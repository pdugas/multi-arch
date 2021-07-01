REQS = git basename uname ldd
CHECK_REQS := $(foreach REQ,$(REQS), $(if $(shell which $(REQ)),ignored,$(error "No $(REQ) in PATH")))

REPO := $(shell git config --get remote.origin.url)
PROJ := $(shell basename $(REPO) .git)

VERSION := $(shell git describe --always --dirty --tag | sed -e 's/^v//')
CPPFLAGS += -DVERSION=\"$(VERSION)\"

DOCKER_USER := pauldugas
DOCKER_TAG:=$(DOCKER_USER)/$(PROJ):$(VERSION)

BINDIR=bin/$(MAKE_HOST)

EG=$(BINDIR)/eg

default: build

help: ## this message
	@echo Available Targets:
	@cat $(MAKEFILE_LIST) | \
		egrep '^[^:]*:.*[#][#].*' | \
		sort | \
		sed -e 's/^\([^:]*\):.*[#][#] *\(.*\)$$/\1|\2/' | \
		awk -F\| '{printf "  %-8s  %s\n", $$1, $$2}'
	@echo

all: $(EG) ## build for the local environment

$(BINDIR)/%: %.c Makefile
	@mkdir -p $(BINDIR)
	$(LINK.c) $< $(LOADLIBES) $(LDLIBS) -o $@

clean: ## remove built content
	@$(RM) -r bin/*

test: ## run tests
	@$(EG) | grep "Howdy" >/dev/null && echo "PASSED" || echo "FAILED"

image: all docker-required
	docker build -t $(DOCKER_TAG) -f .docker/Dockerfile.publish .

image-push:  docker-required
	docker push $(DOCKER_TAG)

build: build-x86-glibc build-arm-glibc build-x86-musl build-arm-musl ## build for all architecures

build-x86-glibc: docker-required ## build for x86/glibc
	@$(MAKE) builder \
		IMAGE=ubuntu:18.04 \
		DOCKERFILE=.docker/Dockerfile.ubuntu

build-x86-musl: docker-required ## build for x86/musl
	@$(MAKE) builder \
		IMAGE=alpine:3.5 \
		DOCKERFILE=.docker/Dockerfile.alpine

build-arm-glibc: docker-required ## build for arm/glibc
	@$(MAKE) builder \
		IMAGE=arm64v8/ubuntu:18.04 \
		DOCKERFILE=.docker/Dockerfile.ubuntu

build-arm-musl: docker-required ## build for arm/musl
	@$(MAKE) builder \
		IMAGE=arm64v8/alpine:3.5 \
		DOCKERFILE=.docker/Dockerfile.alpine

builder: CMD:=make all test
builder: binfmt
	@[ -n "$(IMAGE)" ] || \
		{ echo >&2 "error: IMAGE not set"; exit 1; }
	@[ -n "$(DOCKERFILE)" ] || \
		{ echo >&2 "error: DOCKERFILE not set"; exit 1; }
	docker build \
		-t builder \
		--build-arg IMAGE=$(IMAGE) \
		-f $(DOCKERFILE) \
		.
	docker run --rm -it \
		-v $(shell pwd):/opt/builder \
		-u $(shell id -u):$(shell id -g) \
		builder $(CMD)

docker-required:
	@[ -n "$(shell which docker)" ] || \
		{ echo >&2 "error: docker required"; exit 1; }

binfmt:
	@[ -n "$(wildcard /proc/sys/fs/binfmt_misc/qemu-*)" ] || \
		docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

.PHONY: default help all clean test image image-push build* docker-required
