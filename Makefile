REQS = git uname ldd
CHECK_REQS := $(foreach REQ,$(REQS), $(if $(shell which $(REQ)),ignored,$(error "Missing $(REQ) in PATH")))

REGISTRY ?= ghcr.io
GITHUB_REPOSITORY ?= $(shell git config --get remote.origin.url | cut -d: -f2 | sed 's/\.git$$//')

VERSION ?= $(shell git describe --always --dirty --tag | sed -e 's/^v//')

CPPFLAGS += -DVERSION=\"$(VERSION)\"

ARCH=$(shell uname -m | grep x86 >/dev/null && echo "amd64" || echo "arm64")
LIBC=$(shell ldd --version 2>&1 | grep musl >/dev/null && echo "musl" || echo "gnu")
BINDIR=bin/$(ARCH)-linux-$(LIBC)

EG=$(BINDIR)/eg

OS_LIST := ubuntu alpine
ARCH_LIST := amd64 arm64
PLATFORM_LIST := $(shell echo $(patsubst %,linux/%,$(ARCH_LIST)) | sed 's/ /,/g')

LIBC_ubuntu := gnu
LIBC_alpine := musl

BUILDER ?= appscope-builder

default: all

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

build: ## build each OS/ARCH combination
	@for OS in $(OS_LIST); do for ARCH in $(ARCH_LIST); do \
		$(MAKE) -s build-os-arch OS=$${OS} ARCH=$${ARCH}; \
	done; done

build-os-arch: require-docker
	@[ -n "$(OS)" ] || \
		{ echo >&2 "error: OS not set"; exit 1; }
	@[ -n "$(ARCH)" ] || \
		{ echo >&2 "error: ARCH not set"; exit 1; }
	@$(MAKE) -s builder-$(OS); \
	docker run --rm \
		-v $(shell pwd):/opt/builder \
		-u $(shell id -u):$(shell id -g) \
		--platform linux/$(ARCH) \
		$(REGISTRY)/$(GITHUB_REPOSITORY)-builder:$(OS) \
		make all test

builder-os: IMAGE:=$(REGISTRY)/$(GITHUB_REPOSITORY)-builder:$(OS)
builder-os: require-buildx-builder .docker/Dockerfile.$(OS)
	-docker pull $(IMAGE)
	docker buildx build \
		--builder $(BUILDER) \
		--tag $(IMAGE) \
		--cache-from $(IMAGE) \
		--platform $(PLATFORM_LIST) \
		--label "org.opencontainers.image.description=AppScope builder image for $(OS) ($(LIBC_$(OS)) libc)" \
		--output type=image \
		--file .docker/Dockerfile.$(OS) \
		.

image: ## build each OS image
	@for OS in $(OS_LIST); do \
		$(MAKE) -s image-os OS=$${OS}; \
	done

image-os: TAG:=$(REGISTRY)/$(GITHUB_REPOSITORY)
image-os: .docker/Dockerfile.publish
	@[ -n "$(OS)" ] || \
		{ echo >&2 "error: OS not set"; exit 1; }
	-docker pull $(TAG):latest-$(OS)
	-docker pull $(TAG):$(VERSION)-$(OS)
	docker buildx build \
		$(PUSH) $(if $(LATEST),--tag $(TAG):latest-$(OS)) \
		--tag $(TAG):$(VERSION)-$(OS) \
		--cache-from $(TAG):latest-$(OS) \
		--cache-from $(TAG):$(VERSION)-$(OS) \
		--platform $(PLATFORM_LIST) \
		--output type=image \
		--build-arg IMAGE=$(OS):latest \
		--build-arg LIBC=$(LIBC_$(OS)) \
		--file .docker/Dockerfile.publish \
		.

require-buildx-builder: require-buildx require-qemu-binfmt
	@docker buildx inspect $(BUILDER) >/dev/null 2>&1 || { docker buildx create --name $(BUILDER) --driver docker-container && docker buildx inspect --bootstrap --builder $(BUILDER); }

require-docker:
	@[ -n "$(shell which docker)" ] || \
		{ echo >&2 "error: docker required"; exit 1; }

require-buildx: require-docker
	@docker buildx version >/dev/null || \
		{ echo >&1 "error: docker buildx required"; exit 1; }

require-qemu-binfmt: require-docker
	@[ -n "$(wildcard /proc/sys/fs/binfmt_misc/qemu-*)" ] || \
		docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

.PHONY: default help all clean test build* image* require*
