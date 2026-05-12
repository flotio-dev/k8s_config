# Terraform production environment

This environment provisions the Proxmox VMs used by the Flotio production cluster.

## Prerequisites

- Proxmox API token with VM and datastore permissions.
- Cloud-init template VM, referenced by `template_vm_id`.
- Storage for VM disks, referenced by `vm_datastore_id`.
- Storage for the cloud-init disk, referenced by `snippet_datastore_id`. It must support Proxmox content type `images`; `local-lvm` is usually correct, plain `local` often is not.
- SSH public key for the Ansible user.

## Usage

```bash
cd terraform/environments/prod
terraform init
terraform plan
terraform apply
```

Prefer running Terraform through the root `Makefile`, which loads `config/prod.env` and exports the matching `TF_VAR_*` variables:

```bash
cd ../../..
cp config/prod.env.example config/prod.env
make tf-plan
```

Do not commit `config/prod.env`; it is ignored by Git.

For direct Terraform usage, export the required `TF_VAR_*` variables manually or create a local `terraform.tfvars` file from `terraform.tfvars.example`.

PowerShell token example:

```powershell
$env:TF_VAR_proxmox_api_token = "terraform@pve!terraform=xxxxx"
```

After `terraform apply`, bootstrap Kubernetes with the generated inventory:

```bash
ansible-playbook -i ansible/inventory/hosts.generated.yml ansible/infrastructure.yml --ask-vault-pass
```

## VM layout

| VM | vCPU | RAM | Disk | Role |
|---|---:|---:|---:|---|
| VM | ID | vCPU | RAM | Disk | Role |
|---|---:|---:|---:|---:|---|
| `k8s-cp-01` | 800 | 4 | 6 GiB | 60 GiB | Kubernetes control plane |
| `k8s-worker-01` | 801 | 8 | 12 GiB | 120 GiB | Application worker |
| `k8s-worker-02` | 802 | 8 | 12 GiB | 120 GiB | Application and monitoring worker |
| `k8s-worker-03` | 803 | 8 | 12 GiB | 120 GiB | General Kubernetes worker |
