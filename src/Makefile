SHELL := /bin/bash

.EXPORT_ALL_VARIABLES:

################################################################################
MAINTAINER        ?= Raymond Walker <raymond.walker@greenpeace.org>

# https://github.com/greenpeace/planet4-docker
PARENT_IMAGE			?= gcr.io/planet-4-151612/wordpress
PARENT_VERSION    ?= latest

# Wordpress Helm chart version
CHART_VERSION 		?= 0.0.2

# Use current folder name as prefix for built containers,
# eg planet4-gpi-app planet4-gpi-openresty
CONTAINER_PREFIX  ?= wordpress

################################################################################

# Configure composer source and merge repository data

# Base composer project repository
# FIXME change this to greenpeace/planet4-base once things are settled
GIT_SOURCE        ?= $(CIRCLE_REPOSITORY_URL)

# The branch to checkout of GIT_SOURCE, eg:
# Use local branch name if not set
GIT_REF           ?= $(CIRCLE_TAG)

# If the current commit does not have a tag, use the branch
ifeq ($(strip $(GIT_REF)),)
# Default to git tag on current commit
GIT_REF         := $(CIRCLE_BRANCH)
endif

# No tag or branch? ...  hope for the best
ifeq ($(strip $(GIT_REF)),)
GIT_REF         := $(shell git rev-parse --abbrev-ref HEAD)
endif

################################################################################

# Tag to use on built containers

# Stips away unwanted characters from current branch or tag
BUILD_TAG          ?= $(shell echo $(GIT_REF) | tr -c '[[:alnum:]]._-' '-' | sed 's/-$$//')

################################################################################
#
# Helm deploy configuration
#
# Default and derived values

APP_HOSTNAME        ?= raywalker.it
APP_HOSTPATH        ?= testing
# YAML interprets 'empty' values as 'nil'
ifeq ($(APP_HOSTPATH),<nil>)
# So if APP_HOSTPATH is set, but blank, clean this value
APP_HOSTPATH :=
endif
APP_ENVIRONMENT     ?= production
BUILD_NAMESPACE     ?= gcr.io
GOOGLE_PROJECT_ID   ?= cedar-hawk-222400

NEWRELIC_APPNAME    ?= Wordpress Test
OPENRESTY_IMAGE     ?= $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-openresty
PHP_IMAGE           ?= $(BUILD_NAMESPACE)/$(GOOGLE_PROJECT_ID)/$(CONTAINER_PREFIX)-app

# WP_STATELESS_BUCKET ?= $(CONTAINER_PREFIX)-stateless-$(HELM_NAMESPACE)
# WP_STATELESS_OWNER  ?= cloudstorage@planet-4-151612.iam.gserviceaccount.com

HELM_NAMESPACE      ?= $(APP_HOSTPATH)
HELM_RELEASE        ?= $(CONTAINER_PREFIX)

PULL_POLICY					?= IfNotPresent

DB_HOSTNAME   			?= mysql.db

GCLOUD_CLUSTER      ?= hosting-base
GCLOUD_REGION       ?= us-central1
GCLOUD_ZONE         ?= us-central1-a

PAGESPEED_ENABLED   ?= false

MIN_REPLICA_COUNT ?= 1
MAX_REPLICA_COUNT ?= 2

PHP_MIN_REPLICA_COUNT ?= $(MIN_REPLICA_COUNT)
PHP_MAX_REPLICA_COUNT ?= $(MAX_REPLICA_COUNT)

OPENRESTY_MIN_REPLICA_COUNT ?= $(MIN_REPLICA_COUNT)
OPENRESTY_MAX_REPLICA_COUNT ?= $(MAX_REPLICA_COUNT)

# Secrets
# Values are expected to be stored in Circle build environment

# NEWRELIC_LICENSE    := $(NEWRELIC_LICENSE)
# SQLPROXY_KEY        := $(SQLPROXY_KEY)
# EXIM_USERNAME       := $(EXIM_USERNAME)
# EXIM_PASSWORD       := $(EXIM_PASSWORD)
# WP_AUTH_KEY         := $(WP_AUTH_KEY)
# WP_AUTH_SALT        := $(WP_AUTH_SALT)
WP_DB_USERNAME      ?= $(CONTAINER_PREFIX)
WP_DB_NAME          ?= $(WP_DB_USERNAME)_wordpress
WP_DB_PREFIX        ?= wp_
# WP_DB_PASSWORD      := $(WP_DB_PASSWORD)
# WP_LOGGED_IN_KEY    := $(WP_LOGGED_IN_KEY)
# WP_LOGGED_IN_SALT   := $(WP_LOGGED_IN_SALT)
# WP_NONCE_KEY        := $(WP_NONCE_KEY)
# WP_NONCE_SALT       := $(WP_NONCE_SALT)
# WP_SECURE_AUTH_KEY  := $(WP_SECURE_AUTH_KEY)
# WP_SECURE_AUTH_SALT := $(WP_SECURE_AUTH_SALT)
# WP_STATELESS_KEY    := $(WP_STATELESS_KEY)

################################################################################
#
# Google Cloud Storage Bucket configuration
# Stores built artifacts
#
# GCS bucket to store built source
SOURCE_BUCKET       := $(CONTAINER_PREFIX)-source
SOURCE_BUCKET_PATH  ?= $(BUILD_TAG)

################################################################################


.PHONY: clean test rewrite checkout bake build build-app build-openresty pull push

all: deploy

repo:
	helm repo update

connect:
	# Connect to cluster
	gcloud container clusters get-credentials $(GCLOUD_CLUSTER) \
	--zone $(GCLOUD_ZONE) \
	--project $(GOOGLE_PROJECT_ID)

secrets:
	$(MAKE)
	# Create Helm deploy secrets file from environment
	envsubst < secrets.yaml.in > secrets.yaml
	yamllint secrets.yaml

deploy: deploy-helm

deploy-helm: connect
	$(MAKE) -j repo secrets

	# Ensure Helm release is in a usable state
	# See: https://github.com/kubernetes/helm/issues/4004
	./helm_prepare.sh

	# ./backup_db.sh

	# Upgrade or install deployment to cluster
	./helm_deploy.sh

	rm -f secrets.yaml

	./helm_confirm.sh
	#
	# ./activate_plugins.sh

	./flush_redis.sh
	#
	# ./newrelic_deployment.sh
	#
	# ./configure_redis.sh

		# We don't need this at this time, as all users we need are in all environments.
		# Commenting it out, so that we can save a few seconds out of each build
		# Not deleting it, as we will probably need it again in the future.
	# HELM_NAMESPACE=$(HELM_NAMESPACE) \
	# HELM_RELEASE=$(HELM_RELEASE) \
	# ./run_bash_script_in_php_pod.sh modify_users.sh "$(shell base64 -w 0 users.json)"
	#
	# ./run_post_deploy_scripts.sh
