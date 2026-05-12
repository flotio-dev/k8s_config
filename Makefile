TERRAFORM_DIR := terraform/environments/prod
ANSIBLE_DIR := ansible
ANSIBLE_INVENTORY := ansible/inventory/hosts.generated.yml
ANSIBLE_PLAYBOOK := ansible/infrastructure.yml
ANSIBLE_METALLB_PLAYBOOK := ansible/metallb.yml
ANSIBLE_LONGHORN_PLAYBOOK := ansible/longhorn.yml
ANSIBLE_CLEANUP_PLAYBOOK := ansible/cleanup.yml
ANSIBLE_CONFIG_FILE := $(abspath $(ANSIBLE_DIR)/ansible.cfg)
CONFIG_FILE ?= config/prod.env

-include $(CONFIG_FILE)

export TF_VAR_proxmox_endpoint := $(PROXMOX_ENDPOINT)
export TF_VAR_proxmox_api_token := $(PROXMOX_API_TOKEN)
export TF_VAR_proxmox_insecure := $(PROXMOX_INSECURE)
export TF_VAR_proxmox_node_name := $(PROXMOX_NODE_NAME)
export TF_VAR_template_vm_id := $(TEMPLATE_VM_ID)
export TF_VAR_vm_datastore_id := $(VM_DATASTORE_ID)
export TF_VAR_snippet_datastore_id := $(SNIPPET_DATASTORE_ID)
export TF_VAR_vm_bridge := $(VM_BRIDGE)
export TF_VAR_ipv4_gateway := $(IPV4_GATEWAY)
export TF_VAR_dns_servers := $(DNS_SERVERS)
export TF_VAR_ci_username := $(CI_USERNAME)
export TF_VAR_ssh_public_key := $(SSH_PUBLIC_KEY)
export TF_VAR_k8s_cp_01_vm_id := $(K8S_CP_01_VM_ID)
export TF_VAR_k8s_worker_01_vm_id := $(K8S_WORKER_01_VM_ID)
export TF_VAR_k8s_worker_02_vm_id := $(K8S_WORKER_02_VM_ID)
export TF_VAR_k8s_worker_03_vm_id := $(K8S_WORKER_03_VM_ID)
export TF_VAR_k8s_cp_01_ip_cidr := $(K8S_CP_01_IP_CIDR)
export TF_VAR_k8s_worker_01_ip_cidr := $(K8S_WORKER_01_IP_CIDR)
export TF_VAR_k8s_worker_02_ip_cidr := $(K8S_WORKER_02_IP_CIDR)
export TF_VAR_k8s_worker_03_ip_cidr := $(K8S_WORKER_03_IP_CIDR)
export TF_VAR_k8s_cp_01_cpu := $(K8S_CP_01_CPU)
export TF_VAR_k8s_cp_01_memory_mb := $(K8S_CP_01_MEMORY_MB)
export TF_VAR_k8s_cp_01_disk_gb := $(K8S_CP_01_DISK_GB)
export TF_VAR_k8s_worker_01_cpu := $(K8S_WORKER_01_CPU)
export TF_VAR_k8s_worker_01_memory_mb := $(K8S_WORKER_01_MEMORY_MB)
export TF_VAR_k8s_worker_01_disk_gb := $(K8S_WORKER_01_DISK_GB)
export TF_VAR_k8s_worker_02_cpu := $(K8S_WORKER_02_CPU)
export TF_VAR_k8s_worker_02_memory_mb := $(K8S_WORKER_02_MEMORY_MB)
export TF_VAR_k8s_worker_02_disk_gb := $(K8S_WORKER_02_DISK_GB)
export TF_VAR_k8s_worker_03_cpu := $(K8S_WORKER_03_CPU)
export TF_VAR_k8s_worker_03_memory_mb := $(K8S_WORKER_03_MEMORY_MB)
export TF_VAR_k8s_worker_03_disk_gb := $(K8S_WORKER_03_DISK_GB)

export PROJECT_NAME
export ENV_NAME
export TIMEZONE
export KUBERNETES_VERSION
export KUBERNETES_KUBEADM_VERSION
export KUBERNETES_POD_CIDR
export KUBERNETES_SERVICE_CIDR
export METALLB_ADDRESSES
export CERT_MANAGER_EMAIL
export MONITORING_APPLY_PVE_EXPORTER
export FLANNEL_VERSION
export FLANNEL_NAMESPACE
export METALLB_ENABLED
export METALLB_NAMESPACE
export METALLB_VERSION
export METALLB_POOL_NAME
export METALLB_L2_ADVERTISEMENT_NAME
export INGRESS_NGINX_ENABLED
export INGRESS_NGINX_NAMESPACE
export INGRESS_NGINX_VERSION
export CERT_MANAGER_ENABLED
export CERT_MANAGER_NAMESPACE
export CERT_MANAGER_VERSION
export ARGOCD_ENABLED
export ARGOCD_NAMESPACE
export ARGOCD_VERSION
export MONITORING_ENABLED
export MONITORING_NAMESPACE
export MONITORING_INSTALL_HELM
export METALLB_WAIT_TIMEOUT
export LONGHORN_ENABLED
export LONGHORN_NAMESPACE
export LONGHORN_VERSION
export LONGHORN_WAIT_TIMEOUT
export GHCR_PULL_SECRET_ENABLED
export GHCR_REGISTRY
export GHCR_USERNAME
export GHCR_TOKEN
export GHCR_EMAIL
export GHCR_SECRET_NAME
export GHCR_SECRET_NAMESPACES
export ANDROID_BUILD_ENABLED
export ANDROID_BUILD_NAMESPACE
export ANDROID_BUILD_SERVICE_ACCOUNT_TOKEN_SECRET
export ANDROID_BUILD_CORE_API_TOKEN_SECRET
export ANDROID_BUILD_TOKEN_TARGET_NAMESPACES
export INGRESS_NGINX_WAIT_TIMEOUT
export CERT_MANAGER_WAIT_TIMEOUT
export ARGOCD_WAIT_TIMEOUT
export MONITORING_WAIT_TIMEOUT
export POSTFLIGHT_NODE_READY_TIMEOUT

ifneq ($(strip $(VM_VLAN_ID)),)
export TF_VAR_vm_vlan_id := $(VM_VLAN_ID)
endif

ANSIBLE_VAULT_ARGS := $(if $(ANSIBLE_VAULT_PASSWORD_FILE),--vault-password-file $(ANSIBLE_VAULT_PASSWORD_FILE),--ask-vault-pass)

.PHONY: help config-init show-config check-config vault-pass-fix check-inventory check-tools check tf-init tf-fmt tf-fmt-check tf-validate tf-plan tf-apply tf-destroy ansible-syntax ansible-cleanup-syntax ansible-metallb-syntax ansible-longhorn-syntax ansible-ping ansible-preflight ansible ansible-core ansible-metallb ansible-longhorn prod clean-ansible clean-all clean-vms clean-generated

help:
	@echo "Available targets:"
	@echo "  make config-init      Create local config/prod.env from example"
	@echo "  make show-config      Show selected config file"
	@echo "  make check-config     Check that local config exists"
	@echo "  make vault-pass-fix   Remove executable bit from Ansible Vault password file"
	@echo "  make check-tools      Check local Terraform and Ansible tools"
	@echo "  make check            Run local Terraform and Ansible validations"
	@echo "  make tf-init          Initialize Terraform providers"
	@echo "  make tf-fmt           Format Terraform files"
	@echo "  make tf-fmt-check     Check Terraform formatting"
	@echo "  make tf-validate      Validate Terraform configuration"
	@echo "  make tf-plan          Show Terraform plan"
	@echo "  make tf-apply         Apply Terraform provisioning"
	@echo "  make tf-destroy       Destroy Terraform-managed VMs"
	@echo "  make ansible-syntax   Validate Ansible playbook syntax"
	@echo "  make ansible-cleanup-syntax Validate Ansible cleanup playbook syntax"
	@echo "  make ansible-metallb-syntax Validate MetalLB playbook syntax"
	@echo "  make ansible-longhorn-syntax Validate Longhorn playbook syntax"
	@echo "  make ansible-ping     Test Ansible connectivity"
	@echo "  make ansible-preflight Run Ansible preflight checks"
	@echo "  make ansible          Bootstrap Kubernetes, then install MetalLB and Longhorn"
	@echo "  make ansible-core     Bootstrap Kubernetes and platform tools with MetalLB/Longhorn forced off"
	@echo "  make ansible-metallb  Install MetalLB after the cluster network is stable"
	@echo "  make ansible-longhorn Install Longhorn after the cluster network is stable"
	@echo "  make prod             Provision VMs, then run Ansible"
	@echo "  make clean-ansible    Roll back Kubernetes/Ansible changes on nodes"
	@echo "  make clean-all        Try Ansible rollback, then destroy Terraform VMs"
	@echo "  make clean-vms        Destroy Terraform VMs without Ansible cleanup"
	@echo "  make clean-generated  Remove generated local files"

config-init:
	@if [ ! -f "$(CONFIG_FILE)" ]; then cp config/prod.env.example "$(CONFIG_FILE)"; else echo "$(CONFIG_FILE) already exists"; fi

show-config:
	@echo "CONFIG_FILE=$(CONFIG_FILE)"
	@echo "PROXMOX_ENDPOINT=$(PROXMOX_ENDPOINT)"
	@echo "PROXMOX_NODE_NAME=$(PROXMOX_NODE_NAME)"
	@echo "TEMPLATE_VM_ID=$(TEMPLATE_VM_ID)"
	@echo "VM_DATASTORE_ID=$(VM_DATASTORE_ID)"
	@echo "SNIPPET_DATASTORE_ID=$(SNIPPET_DATASTORE_ID)"
	@echo "K8S_CP_01_VM_ID=$(K8S_CP_01_VM_ID)"
	@echo "K8S_WORKER_01_VM_ID=$(K8S_WORKER_01_VM_ID)"
	@echo "K8S_WORKER_02_VM_ID=$(K8S_WORKER_02_VM_ID)"
	@echo "K8S_WORKER_03_VM_ID=$(K8S_WORKER_03_VM_ID)"
	@echo "K8S_CP_01_IP_CIDR=$(K8S_CP_01_IP_CIDR)"
	@echo "K8S_WORKER_01_IP_CIDR=$(K8S_WORKER_01_IP_CIDR)"
	@echo "K8S_WORKER_02_IP_CIDR=$(K8S_WORKER_02_IP_CIDR)"
	@echo "K8S_WORKER_03_IP_CIDR=$(K8S_WORKER_03_IP_CIDR)"
	@echo "KUBERNETES_VERSION=$(KUBERNETES_VERSION)"
	@echo "METALLB_ADDRESSES=$(METALLB_ADDRESSES)"
	@echo "CERT_MANAGER_EMAIL=$(CERT_MANAGER_EMAIL)"
	@echo "MONITORING_APPLY_PVE_EXPORTER=$(MONITORING_APPLY_PVE_EXPORTER)"

check-config:
	@test -f "$(CONFIG_FILE)" || (echo "Missing $(CONFIG_FILE). Run: make config-init" && exit 1)

vault-pass-fix:
	@test -n "$(ANSIBLE_VAULT_PASSWORD_FILE)" || (echo "ANSIBLE_VAULT_PASSWORD_FILE is empty in $(CONFIG_FILE)" && exit 1)
	chmod 600 "$(ANSIBLE_VAULT_PASSWORD_FILE)"

check-inventory:
	@test -f "$(ANSIBLE_INVENTORY)" || (echo "Missing $(ANSIBLE_INVENTORY). Run Terraform first: make tf-apply" && exit 1)

check-tools:
	@command -v terraform >/dev/null || (echo "Missing terraform in PATH" && exit 1)
	@command -v ansible >/dev/null || (echo "Missing ansible in PATH" && exit 1)
	@command -v ansible-playbook >/dev/null || (echo "Missing ansible-playbook in PATH" && exit 1)

check: check-tools tf-fmt-check tf-validate ansible-syntax ansible-cleanup-syntax ansible-metallb-syntax ansible-longhorn-syntax

tf-init: check-config
	terraform -chdir=$(TERRAFORM_DIR) init

tf-fmt:
	terraform fmt -recursive terraform

tf-fmt-check:
	terraform fmt -check -recursive terraform

tf-validate: tf-init
	terraform -chdir=$(TERRAFORM_DIR) validate

tf-plan: tf-validate
	terraform -chdir=$(TERRAFORM_DIR) plan

tf-apply: tf-validate
	terraform -chdir=$(TERRAFORM_DIR) apply

tf-destroy: tf-init
	terraform -chdir=$(TERRAFORM_DIR) destroy

ansible-syntax:
	ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_FILE) ansible-playbook --syntax-check -i ansible/inventory/hosts.yml $(ANSIBLE_PLAYBOOK)

ansible-cleanup-syntax:
	ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_FILE) ansible-playbook --syntax-check -i ansible/inventory/hosts.yml $(ANSIBLE_CLEANUP_PLAYBOOK)

ansible-metallb-syntax:
	ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_FILE) ansible-playbook --syntax-check -i ansible/inventory/hosts.yml $(ANSIBLE_METALLB_PLAYBOOK)

ansible-longhorn-syntax:
	ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_FILE) ansible-playbook --syntax-check -i ansible/inventory/hosts.yml $(ANSIBLE_LONGHORN_PLAYBOOK)

ansible-ping: check-inventory
	ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_FILE) ansible all -i $(ANSIBLE_INVENTORY) -m ping

ansible-preflight: check-inventory
	ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_FILE) ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_PLAYBOOK) --tags preflight $(ANSIBLE_VAULT_ARGS)

ansible: ansible-core ansible-metallb ansible-longhorn

ansible-core: check-inventory
	METALLB_ENABLED=false LONGHORN_ENABLED=false ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_FILE) ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_PLAYBOOK) $(ANSIBLE_VAULT_ARGS)

ansible-metallb: check-inventory
	METALLB_ENABLED=true ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_FILE) ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_METALLB_PLAYBOOK) $(ANSIBLE_VAULT_ARGS)

ansible-longhorn: check-inventory
	LONGHORN_ENABLED=true ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_FILE) ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_LONGHORN_PLAYBOOK) $(ANSIBLE_VAULT_ARGS)

prod: tf-fmt tf-apply ansible

clean-ansible: check-inventory
	ANSIBLE_CONFIG=$(ANSIBLE_CONFIG_FILE) ansible-playbook -i $(ANSIBLE_INVENTORY) $(ANSIBLE_CLEANUP_PLAYBOOK) $(ANSIBLE_VAULT_ARGS)

clean-all:
	-$(MAKE) clean-ansible
	$(MAKE) tf-destroy
	$(MAKE) clean-generated

clean-vms: tf-destroy clean-generated

clean-generated:
	rm -f "$(ANSIBLE_INVENTORY)"
