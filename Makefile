# SPDX-FileCopyrightText: © 2019 Clifford Weinmann <https://www.cliffordweinmann.com/>
#
# SPDX-License-Identifier: MIT-0

# Get current versions
MAILCATCHER_VERSION := $(shell bash ./getenv MAILCATCHER_VERSION)
RELEASE_VERSION := $(shell bash ./getenv RELEASE_VERSION)
IMAGE_NAME := $(shell bash ./getenv IMAGE_NAME)

# Add date into release version to distinguish between image differences resulting from `apk update` & `apk upgrade` steps
IMAGE_TAG := $(shell bash ./getenv IMAGE_TAG)
GIT_REVISION := $(shell git rev-parse @)
BUILD_DATE := $(shell TZ=UTC date '+%Y-%m-%d')
BUILD_TIME := $(shell TZ=UTC date '+%Y-%m-%dT%H:%M:%SZ')

# REGISTRY_NAME := ghcr.io
# REGISTRY_USER := clifford2
# REPOBASE := $(REGISTRY_NAME)/$(REGISTRY_USER)
IMGRELNAME := $(REPOBASE)/$(IMAGE_NAME)

# Port numbers
UID := $(shell id -u)
ifeq ($(UID),0)
	SMTP_PORT := 587
else
	SMTP_PORT := 2525
endif
HTTP_PORT := 8080

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


.PHONY: help
help:
	@echo "There is no default target for $(IMAGE_NAME):$(IMAGE_TAG) yet - please pick a suitable target manually"
	@echo "We're using $(CONTAINER_ENGINE) on $(BUILDARCH)"
	@echo "SMTP PORT: $(SMTP_PORT)"

# After any changing .env, fix the image tags in other files
.PHONY: fixtags
fixtags:
	sed -i -e "s|$(IMAGE_NAME):..*$$|$(IMAGE_NAME):$(IMAGE_TAG)|" README.md
	sed -i -e "s|image: $(IMAGE_NAME):..*$$|image: $(IMAGE_NAME):$(IMAGE_TAG)|" docker-compose.yml
	sed -i -e "s|image: $(IMAGE_NAME):..*$$|image: $(IMAGE_NAME):$(IMAGE_TAG)|" k8s.yaml
	sed -i -e "s|version: ..*$$|version: $(IMAGE_TAG)|" k8s.yaml

.PHONY: build
build:
	$(BUILD_CMD) --pull --build-arg MAILCATCHER_VERSION=$(MAILCATCHER_VERSION) --build-arg APP_VERSION=$(IMAGE_TAG) --build-arg BUILD_DATE=$(BUILD_DATE) --build-arg BUILD_TIME=$(BUILD_TIME) -t $(IMAGE_NAME):$(IMAGE_TAG) .
	$(CONTAINER_ENGINE) tag $(IMAGE_NAME):$(IMAGE_TAG) $(IMAGE_NAME):latest

.PHONY: tag
tag: .check-depends
	test ! -z "$(REPOBASE)" || (echo "Please specify REPOBASE" && false)
	$(CONTAINER_ENGINE) tag $(IMAGE_NAME):$(IMAGE_TAG) $(IMGRELNAME):$(IMAGE_TAG)
	$(CONTAINER_ENGINE) tag $(IMAGE_NAME):$(IMAGE_TAG) $(IMGRELNAME):$(MAILCATCHER_VERSION)
	$(CONTAINER_ENGINE) tag $(IMAGE_NAME):$(IMAGE_TAG) $(IMGRELNAME):latest

.PHONY: push
push: tag
	test ! -z "$(REPOBASE)" || (echo "Please specify REPOBASE" && false)
	test ! -z "$(REGISTRY_NAME)" && $(CONTAINER_ENGINE) login -u $(REGISTRY_USER) $(REGISTRY_NAME) || echo 'Not logging into registry'
	$(CONTAINER_ENGINE) push $(IMGRELNAME):$(IMAGE_TAG)
	$(CONTAINER_ENGINE) push $(IMGRELNAME):$(MAILCATCHER_VERSION)
	$(CONTAINER_ENGINE) push $(IMGRELNAME):latest

.PHONY: run
run:
	$(CONTAINER_ENGINE) run -d --rm -p $(SMTP_PORT):2525 -p $(HTTP_PORT):8080 --name mailcatcher --replace=true $(IMAGE_NAME):$(IMAGE_TAG)
	@sleep 2
	$(CONTAINER_ENGINE) exec -it mailcatcher hello
	@echo "Web interface: http://0.0.0.0:$(HTTP_PORT)/"
	@command -v xdg-open > /dev/null && (xdg-open http://0.0.0.0:$(HTTP_PORT)/ 2>/dev/null) || true

.PHONY: hello
hello:
	$(CONTAINER_ENGINE) exec -it mailcatcher hello

.PHONY: stop
stop:
	@$(CONTAINER_ENGINE) stop mailcatcher

.PHONY: git-push
git-push: fixtags
	@git add .
	@git commit
	@git tag -m "Version $(IMAGE_TAG)" $(IMAGE_TAG)
	@git push --follow-tags

# Verify that we have all required dependencies installed
.PHONY: .check-depends
.check-depends:
	command -v podman || command -v docker
