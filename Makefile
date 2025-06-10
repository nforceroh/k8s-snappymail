#!/usr/bin/make -f

SHELL := /bin/bash
IMG_NAME := snappymail
IMG_REPO := nforceroh
IMG_NS := homelab
IMG_REG := harbor.k3s.nf.lab
DATE_VERSION := $(shell date +"v%Y%m%d%H%M" )
BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
DOCKERCMD := docker

ifeq ($(BRANCH),dev)
	VERSION := dev
else
	VERSION := $(BRANCH)
endif

#oc get route default-route -n openshift-image-registry
#podman login -u sylvain -p $(oc whoami -t) default-route-openshift-image-registry.apps.ocp.nf.lab

.PHONY: all build push gitcommit gitpush create
all: build push 
git: gitcommit gitpush 

build: 
	@echo "Building $(IMG_NAME)image"
	$(DOCKERCMD) build \
		--tag $(IMG_REPO)/$(IMG_NAME) . --no-cache

gitcommit:
	git push

gitpush:
	@echo "Building $(IMG_NAME):$(VERSION) image"
	git tag -a $(VERSION) -m "Update to $(VERSION)"
	git push --tags

push: 
	@echo "Tagging and Pushing $(IMG_NAME):$(VERSION) image"
ifeq ($(VERSION), dev)
	$(DOCKERCMD) tag $(IMG_REPO)/$(IMG_NAME) docker.io/$(IMG_REPO)/$(IMG_NAME):dev
	$(DOCKERCMD) push docker.io/$(IMG_REPO)/$(IMG_NAME):dev
else
#	$(DOCKERCMD) tag $(IMG_REPO)/$(IMG_NAME) docker.io/$(IMG_REPO)/$(IMG_NAME):$(DATE_VERSION)
#	$(DOCKERCMD) tag $(IMG_REPO)/$(IMG_NAME) docker.io/$(IMG_REPO)/$(IMG_NAME):latest
	$(DOCKERCMD) tag $(IMG_REPO)/$(IMG_NAME) $(IMG_REG)/$(IMG_NS)/$(IMG_NAME):$(DATE_VERSION)
	$(DOCKERCMD) tag $(IMG_REPO)/$(IMG_NAME) $(IMG_REG)/$(IMG_NS)/$(IMG_NAME):latest
	$(DOCKERCMD) push $(IMG_REG)/$(IMG_NS)/$(IMG_NAME):$(DATE_VERSION)
#	$(DOCKERCMD) push $(IMG_REG)/$(IMG_NS)/$(IMG_NAME):latest
#	$(DOCKERCMD) push docker.io/$(IMG_REPO)/$(IMG_NAME):$(DATE_VERSION)
#	$(DOCKERCMD) push docker.io/$(IMG_REPO)/$(IMG_NAME):latest
endif

end:
	@echo "Done!"