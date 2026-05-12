# Terraform

Terraform provisions the Proxmox VM layer. Ansible then configures the operating systems and Kubernetes, and Argo CD deploys the application manifests.

```text
Terraform -> Proxmox VMs -> Ansible -> Kubernetes platform -> Argo CD apps
```

Start with `environments/prod`.

Local environment values are centralized in `../config/prod.env`. Create it from `../config/prod.env.example`, then run the root `Makefile`.

```bash
make tf-plan
make tf-apply
```

Terraform writes the generated Ansible inventory at `ansible/inventory/hosts.generated.yml`.

Detailed explanation: `doc/provisioning-terraform-proxmox.md`.
