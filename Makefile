REQS = git basename uname ldd
CHECK_REQS := $(foreach REQ,$(REQS), $(if $(shell which $(REQ)),ignored,$(error "No $(REQ) in PATH")))

REPO := $(shell git config --get remote.origin.url)
PROJ := $(shell basename $(REPO) .git)

VERSION := $(shell git describe --always --dirty --tag | sed -e 's/^v//')
CPPFLAGS += -DVERSION=\"$(VERSION)\"

DOCKER_USER := pauldugas
DOCKER_TAG:=$(DOCKER_USER)/$(PROJ):$(VERSION)

ARCH=$(shell echo $(MAKE_HOST) | awk -F - '{printf "%s-linux-%s", $$1, $$NF}')
BINDIR=bin/$(ARCH)

EG=$(BINDIR)/eg

eg:
	echo $(MAKE_HOST)
	uname -m


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

build: build-x86-gnu build-arm-gnu build-x86-musl build-arm-musl ## build for all architecures

build-x86-gnu: docker-required ## build for x86/gnu
	@$(MAKE) builder \
		ARCH=amd64/ \
		IMAGE=ghcr.io/pdugas/multi-arch/builder:amd-gnu \
		DOCKERFILE=.docker/Dockerfile.ubuntu

build-x86-musl: docker-required ## build for x86/musl
	@$(MAKE) builder \
		ARCH=amd64/ \
		IMAGE=ghcr.io/pdugas/multi-arch/builder:amd-musl \
		DOCKERFILE=.docker/Dockerfile.alpine

build-arm-gnu: docker-required ## build for arm/gnu
	@$(MAKE) builder \
		ARCH=arm64v8/ \
		IMAGE=ghcr.io/pdugas/multi-arch/builder:arm-gnu \
		DOCKERFILE=.docker/Dockerfile.ubuntu

build-arm-musl: docker-required ## build for arm/musl
	@$(MAKE) builder \
		ARCH=arm64v8/ \
		IMAGE=ghcr.io/pdugas/multi-arch/builder:arm-musl \
		DOCKERFILE=.docker/Dockerfile.alpine

builder: qemu-binfmt
	@[ -n "$(ARCH)" ] || \
		{ echo >&2 "error: ARCH not set"; exit 1; }
	@[ -n "$(IMAGE)" ] || \
		{ echo >&2 "error: IMAGE not set"; exit 1; }
	@[ -n "$(DOCKERFILE)" ] || \
		{ echo >&2 "error: DOCKERFILE not set"; exit 1; }
	-docker pull $(IMAGE)
	docker build \
		--tag $(IMAGE) \
		--cache-from $(IMAGE) \
		--label "org.opencontainers.image.description=Builder for $(dir $(ARCH)) and $(notdir $(DOCKERFILE))" \
		--build-arg ARCH=$(ARCH) \
		--file $(DOCKERFILE) \
		.
	docker run --rm \
		-v $(shell pwd):/opt/builder \
		-u $(shell id -u):$(shell id -g) \
		$(IMAGE) make all test
	if echo $(GITHUB_REF) | egrep '^refs/heads/main$$' >/dev/null; then \
		docker push $(IMAGE); \
	fi

image: all docker-required
	docker buildx build \
		--platform linux/arm64/v8,linux/amd64 \
		-t $(DOCKER_TAG) \
		-f .docker/Dockerfile.publish .

image-push:  docker-required
	docker push $(DOCKER_TAG)

docker-required:
	@[ -n "$(shell which docker)" ] || \
		{ echo >&2 "error: docker required"; exit 1; }

qemu-binfmt:
	@[ -n "$(wildcard /proc/sys/fs/binfmt_misc/qemu-*)" ] || \
		docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

.PHONY: default help all clean test image image-push build* docker-required
