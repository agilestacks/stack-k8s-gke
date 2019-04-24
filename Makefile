.DEFAULT_GOAL := deploy

DOMAIN_NAME    ?= supergke.gcp.superhub.io
COMPONENT_NAME ?= stack-k8s-gke

NAME           := $(shell echo $(DOMAIN_NAME) | cut -d. -f1)
BASE_DOMAIN    := $(shell echo $(DOMAIN_NAME) | cut -d. -f2-)

export TF_VAR_base_domain ?= $(BASE_DOMAIN)
export TF_VAR_project ?= superhub
export TF_VAR_region ?= us-central1
export TF_VAR_cluster_name := $(NAME)
export TF_VAR_node_machine_type ?= g1-small
export TF_VAR_min_node_count ?= 1
export TF_VAR_max_node_count ?= 3

terraform   ?= terraform-v0.11
export TF_LOG      ?= info
export TF_DATA_DIR ?= .terraform/$(DOMAIN_NAME)
export TF_LOG_PATH ?= $(TF_DATA_DIR)/terraform.log
TF_CLI_ARGS := -no-color -input=false -lock=false
TFPLAN := $(TF_DATA_DIR)/$(DOMAIN_NAME).tfplan

init:
	@mkdir -p $(TF_DATA_DIR)
	$(terraform) init $(TF_CLI_ARGS)

plan:
	$(terraform) plan $(TF_CLI_ARGS) -out=$(TFPLAN)

apply:
	$(terraform) apply $(TF_CLI_ARGS) -Xshadow=false $(TFPLAN)

deploy: init plan apply

destroy: TF_CLI_ARGS:=-destroy $(TF_CLI_ARGS)
destroy: plan	

undeploy: init destroy apply
