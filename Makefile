.DEFAULT_GOAL := deploy

DOMAIN_NAME    ?= supergke.gcp.superhub.io
COMPONENT_NAME ?= stack-k8s-gke

NAME           := $(shell echo $(DOMAIN_NAME) | cut -d. -f1)
BASE_DOMAIN    := $(shell echo $(DOMAIN_NAME) | cut -d. -f2-)
NAME2          := $(shell echo $(DOMAIN_NAME) | sed -E -e 's/[^[:alnum:]]+/-/g' | cut -c1-40 | sed -e 's/-$$//')

STATE_BUCKET ?= gcp-superhub-io
STATE_REGION ?= us-central1

SERVICE_ACCOUNT ?= asi

LOCATION := $(REGION)
LOCATION_KIND :=--region
DEFAULT_ZONE := $(REGION)-b
ifneq (,$(ZONE))
	LOCATION := $(ZONE)
	LOCATION_KIND := --zone
	DEFAULT_ZONE := $(ZONE)
endif

export TF_VAR_domain ?= $(DOMAIN_NAME)
export TF_VAR_base_domain ?= $(BASE_DOMAIN)
export TF_VAR_project ?= $(PROJECT)
export TF_VAR_location ?= $(LOCATION)
export TF_VAR_cluster_name := $(or $(CLUSTER_NAME),$(NAME2))
export TF_VAR_node_machine_type ?= g1-small
export TF_VAR_min_node_count ?= 1
export TF_VAR_max_node_count ?= 3
export TF_VAR_preemptible ?=
export TF_VAR_addons_istio ?= false

terraform ?= terraform-v0.11

export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log
TF_CLI_ARGS := -no-color -input=false -lock=false
TFPLAN := $(TF_DATA_DIR)/$(DOMAIN_NAME).tfplan

gcloud ?= gcloud
kubectl ?= kubectl --context=gke_$(PROJECT)_$(LOCATION)_$(TF_VAR_cluster_name)

deploy: init import plan apply gcontext createsa storage token region output

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
	$(gcloud) container clusters get-credentials $(TF_VAR_cluster_name) $(LOCATION_KIND) $(TF_VAR_location)
.PHONY: gcontext

createsa:
	$(kubectl) -n default get serviceaccount $(SERVICE_ACCOUNT) || \
		($(kubectl) -n default create serviceaccount $(SERVICE_ACCOUNT) && sleep 17)
	$(kubectl) get clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding || \
		($(kubectl) create clusterrolebinding $(SERVICE_ACCOUNT)-cluster-admin-binding \
			--clusterrole=cluster-admin --serviceaccount=default:$(SERVICE_ACCOUNT) && sleep 7)
.PHONY: createsa

storage:
	$(kubectl) apply -f storage-class.yaml
.PHONY: storage

token:
	$(eval SECRET:=$(shell $(kubectl) -n default get serviceaccount $(SERVICE_ACCOUNT) -o json | \
		jq -r '.secrets[] | select(.name | contains("token")).name'))
	$(eval TOKEN:=$(shell $(kubectl) -n default get secret $(SECRET) -o json | \
		jq -r '.data.token'))
.PHONY: token

region:
	$(eval REGION=$(shell echo $(LOCATION) | cut -d- -f1-2))
.PHONY: region

import:
	-$(terraform) import -provider=google $(TF_OPTS) google_dns_managed_zone.main $$(echo $(DOMAIN_NAME) | sed -e 's/\./-/g')
	-$(terraform) import -provider=google $(TF_OPTS) google_dns_managed_zone.internal i-$$(echo $(DOMAIN_NAME) | sed -e 's/\./-/g')
	-$(terraform) import -provider=google $(TF_OPTS) google_compute_network.gke_vpc $(TF_VAR_cluster_name)-vpc
.PHONY: import

output:
	@echo
	@echo Outputs:
	@echo dns_name = $(NAME)
	@echo dns_base_domain = $(BASE_DOMAIN)
	@echo cluster_name = $(TF_VAR_cluster_name)
	@echo token = $(TOKEN) | $(HUB) util otp
	@echo region = $(REGION)
	@echo zone = $(DEFAULT_ZONE)
	@echo
.PHONY: output

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan

undeploy: init import destroy apply
