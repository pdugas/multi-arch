REPO := $(shell git config --get remote.origin.url)
PROJ := $(shell basename -s .git $(REPO))

VERSION := $(shell git describe --always --dirty --tag | sed -e 's/^v//')

DOCKER_USER := pauldugas
DOCKER_TAG:=$(DOCKER_USER)/$(PROJ):$(VERSION)

CPPFLAGS += -DVERSION=\"$(VERSION)\"

all: eg

clean:
	$(RM) eg

test: all
	./eg | grep "Howdy" >/dev/null && echo "PASSED" || echo "FAILED"

image: all
	docker build -t $(DOCKER_TAG) .

image-push: 
	docker push $(DOCKER_TAG)

.PHONE: all clean test image image-push
