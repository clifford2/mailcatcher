# SPDX-FileCopyrightText: © 2019 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

# Use podman or docker?
ifeq ($(shell command -v podman 2> /dev/null),)
	CONTAINER_ENGINE := docker
else
	CONTAINER_ENGINE := podman
endif

# Configure build commands
ifeq ($(CONTAINER_ENGINE),podman)
	BUILDARCH := $(shell podman version --format '{{.Client.OsArch}}' | cut -d/ -f2)
	BUILD_NOLOAD := podman build
	BUILD_CMD := $(BUILD_NOLOAD)
else
	BUILDARCH := $(shell docker version --format '{{.Client.Arch}}')
	BUILD_NOLOAD := docker buildx build
	BUILD_CMD := $(BUILD_NOLOAD) --load
endif
# Get current versions
MAILCATCHER_VERSION := $(shell bash ./getenv MAILCATCHER_VERSION)
RELEASE_VERSION := $(shell bash ./getenv RELEASE_VERSION)
IMAGE_NAME := $(shell bash ./getenv IMAGE_NAME)
IMAGE_TAG := $(shell bash ./getenv IMAGE_TAG)


.PHONY: hello
hello:
	@echo "There is no default target for $(IMAGE_NAME):$(IMAGE_TAG) yet - please pick a suitable target manually"
	@echo "We're using $(CONTAINER_ENGINE) on $(BUILDARCH)"

# After any changing .env, fix the image tags in other files
.PHONY: fixtags
fixtags:
	sed -i -e "s|^ARG MAILCATCHER_VERSION=..*$$|ARG MAILCATCHER_VERSION=$(MAILCATCHER_VERSION)|" Dockerfile
	sed -i -e "s|^podman run \(..*\) $(IMAGE_NAME):..*$$|podman run \1 $(IMAGE_NAME):$(IMAGE_TAG)|" README.md
	sed -i -e "s|image: $(IMAGE_NAME):..*$$|image: $(IMAGE_NAME):$(IMAGE_TAG)|" docker-compose.yml
	sed -i -e "s|image: $(IMAGE_NAME):..*$$|image: $(IMAGE_NAME):$(IMAGE_TAG)|" k8s.yaml
	sed -i -e "s|version: ..*$$|version: $(IMAGE_TAG)|" k8s.yaml

.PHONY: build
build:
	$(BUILD_CMD) --pull -t $(IMAGE_NAME):$(IMAGE_TAG) .
	$(CONTAINER_ENGINE) tag $(IMAGE_NAME):$(IMAGE_TAG) $(IMAGE_NAME):latest

.PHONY: run
run:
	$(CONTAINER_ENGINE) run -d --rm -p 2525:2525 -p 8080:8080 --name mailcatcher --replace=true $(IMAGE_NAME):$(IMAGE_TAG)
	@sleep 2
	$(CONTAINER_ENGINE) exec -it mailcatcher hello 
	@echo "Web interface: http://0.0.0.0:8080/"

.PHONY: stop
stop:
	@$(CONTAINER_ENGINE) stop mailcatcher

.PHONY: git-push
git-push:
	@git add .
	@git commit
	@git tag "$(IMAGE_TAG)"
	@git push --follow-tags

# No longer required - performed by GitHub Action instead
# .PHONY: docker-push
# docker-push:
#	$(CONTAINER_ENGINE) login docker.io
#	$(CONTAINER_ENGINE) push $(IMAGE_NAME):$(IMAGE_TAG)
#	$(CONTAINER_ENGINE) tag $(IMAGE_NAME):$(IMAGE_TAG) $(IMAGE_NAME):latest
# 	$(CONTAINER_ENGINE) push $(IMAGE_NAME):latest
