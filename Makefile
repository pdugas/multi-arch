REPO := $(shell git config --get remote.origin.url)
PROJ := $(shell basename -s .git $(REPO))

VERSION := $(shell git describe --always --dirty --tag | sed -e 's/^v//')

DOCKER_USER := pauldugas

CPPFLAGS += -DVERSION=\"$(VERSION)\"

all: eg

clean:
	$(RM) eg

test: all
	./eg | grep "Howdy" >/dev/null && echo "PASSED" || echo "FAILED"

image: TAG:=$(DOCKER_USER)/$(PROJ):$(VERSION)
image: all
	docker build -t $(TAG) .

.PHONE: all clean test image
