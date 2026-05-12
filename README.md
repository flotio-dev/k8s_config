# k8s_config

Infrastructure and Kubernetes deployment repository for the **flotio** project.

The target workflow is:

```text
config/prod.env -> Terraform Proxmox VMs -> generated Ansible inventory -> kubeadm cluster -> platform tools -> Argo CD apps
```

## Structure

- `config/`: local production variables. Start here.
- `terraform/`: Proxmox VM provisioning.
- `ansible/`: OS, kubeadm and platform bootstrap.
- `argocd/`: Argo CD application definitions.
- `manifest/`: Kubernetes application and platform manifests.
- `archive/`: ignored legacy material.

## Production Bootstrap

Run from WSL:

```bash
cd /mnt/c/Users/jekte/travail/gpe/k8s_config
make config-init
```

Edit `config/prod.env`, then validate locally:

```bash
make check
```

Provision production:

```bash
make prod
```

`make prod` initializes and validates Terraform, applies the Proxmox VM layer, uses Terraform to write `ansible/inventory/hosts.generated.yml`, then runs the Ansible bootstrap.

## Useful Targets

```bash
make tf-plan
make tf-apply
make ansible-preflight
make ansible
make clean-ansible
make clean-all
make clean-generated
```

## Secrets

`config/prod.env` is ignored by Git and can contain local endpoints, IPs, Proxmox tokens and SSH public keys. Application passwords and database secrets should stay encrypted with Ansible Vault, SOPS, SealedSecrets or ExternalSecrets.
