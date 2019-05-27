SHELL := /bin/bash
.DEFAULT_GOAL := deploy

DOMAIN_NAME    ?= supergke.gcp.superhub.io
COMPONENT_NAME ?= stack-k8s-gke

NAME           := $(shell echo $(DOMAIN_NAME) | cut -d. -f1)
BASE_DOMAIN    := $(shell echo $(DOMAIN_NAME) | cut -d. -f2-)

STATE_BUCKET ?= gcp-superhub-io
STATE_REGION ?= us-central1

SERVICE_ACCOUNT ?= asi

LOCATION := $(REGION)
LOCATION_KIND :=--region
ifneq (,$(ZONE))
	LOCATION=$(ZONE)
	LOCATION_KIND=--zone
endif

export TF_VAR_base_domain ?= $(BASE_DOMAIN)
export TF_VAR_project ?= $(PROJECT)
export TF_VAR_location ?= $(LOCATION)
export TF_VAR_cluster_name := $(CLUSTER_NAME)
export TF_VAR_node_machine_type ?= g1-small
export TF_VAR_min_node_count ?= 1
export TF_VAR_max_node_count ?= 3
export TF_VAR_addons_istio ?= disabled

terraform ?= terraform-v0.11

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log
TF_CLI_ARGS := -no-color -input=false -lock=false
TFPLAN := $(TF_DATA_DIR)/$(DOMAIN_NAME).tfplan

gcloud ?= gcloud
kubectl ?= kubectl --context=gke_$(PROJECT)_$(LOCATION)_$(CLUSTER_NAME)

init:
	@mkdir -p $(TF_DATA_DIR)
	$(terraform) init -get=true $(TF_CLI_ARGS) -reconfigure -force-copy \
		-backend-config="bucket=$(STATE_BUCKET)" \
		-backend-config="prefix=$(DOMAIN_NAME)/$(COMPONENT_NAME)"
.PHONY: init

plan:
	$(terraform) plan $(TF_CLI_ARGS) \
		-refresh=true -module-depth=-1 -out=$(TFPLAN)
.PHONY: plan

apply:
	$(terraform) apply $(TF_CLI_ARGS) -Xshadow=false $(TFPLAN)
	@echo
.PHONY: apply

gcontext:
	$(gcloud) container clusters get-credentials $(CLUSTER_NAME) $(LOCATION_KIND) $(TF_VAR_location)
.PHONY: gcontext

createsa:
	$(kubectl) get -n default serviceaccount $(SERVICE_ACCOUNT) || \
		$(kubectl) create -n default serviceaccount $(SERVICE_ACCOUNT)
	$(kubectl) get clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding || \
		$(kubectl) create clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding \
			--clusterrole=cluster-admin --serviceaccount=default:$(SERVICE_ACCOUNT)
.PHONY: createsa

storage:
	$(kubectl) apply -f storage-class.yaml
.PHONY: storage

token:
	$(eval SECRET=$(shell $(kubectl) get serviceaccount $(SERVICE_ACCOUNT) -o json | \
		jq '.secrets[] | select(.name | contains("token")).name'))
	$(eval TOKEN_BASE64=$(shell $(kubectl) get secret $(SECRET) -o json | \
		jq '.data.token'))
	$(eval TOKEN=$(shell openssl enc -A -base64 -d <<< $(TOKEN_BASE64)))
.PHONY: token

region:
	$(eval REGION=$(shell echo $(LOCATION) | cut -d- -f1-2))
.PHONY: region

output:
	@echo
	@echo Outputs:
	@echo dns_name = $(NAME)
	@echo dns_base_domain = $(BASE_DOMAIN)
	@echo token = $(TOKEN)
	@echo region = $(REGION)
	@echo
.PHONY: output

deploy: init plan apply gcontext createsa storage token region output

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

undeploy: init destroy apply
