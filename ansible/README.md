# Ansible Infrastructure

First draft Ansible layout for bootstrapping a kubeadm Kubernetes cluster with containerd, Flannel and core platform tools.

## Source Of Truth

Production values are loaded from `../config/prod.env` by the root `Makefile`.

- Terraform writes `inventory/hosts.generated.yml`.
- `inventory/group_vars/all/vars.yml` reads operational values from environment variables exported by `make`.
- `inventory/group_vars/all/vault.yml` should be encrypted before storing real secrets.

The static `inventory/hosts.yml` remains only for local syntax checks and manual experiments.

## Install Dependencies

```bash
ansible-galaxy collection install -r requirements.yml
```

## Run

```bash
make ansible-ping
make ansible-preflight
make ansible
```

## Cleanup

Rollback Kubernetes and platform changes on the existing VMs:

```bash
make clean-ansible
```

Then destroy Terraform-managed VMs:

```bash
make clean-all
```

`clean-ansible` is an offline node cleanup: it does not call `kubectl` and does not require a working Kubernetes API server. It stops kubelet/containerd, runs a local `kubeadm reset`, removes Kubernetes/containerd/Helm packages, and deletes Kubernetes config directories. It cannot undo package upgrades or restore an old swap entry that was removed from `/etc/fstab`.

## Run Only Platform Tools

```bash
ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i ansible/inventory/hosts.generated.yml ansible/infrastructure.yml --tags tools
ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i ansible/inventory/hosts.generated.yml ansible/infrastructure.yml --tags metallb
ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i ansible/inventory/hosts.generated.yml ansible/infrastructure.yml --tags ingress
ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i ansible/inventory/hosts.generated.yml ansible/infrastructure.yml --tags cert_manager
ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i ansible/inventory/hosts.generated.yml ansible/infrastructure.yml --tags argocd
ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i ansible/inventory/hosts.generated.yml ansible/infrastructure.yml --tags monitoring
```

## Verify

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl -n kube-flannel get pods
kubectl -n metallb-system get pods
kubectl -n ingress-nginx get svc,pods
kubectl -n cert-manager get pods
kubectl -n argocd get pods
kubectl -n argocd get applications
kubectl -n monitoring get pods
kubectl -n monitoring get servicemonitors,prometheusrules
kubectl cluster-info
```

## Proxmox Exporter

`pve-exporter` is disabled by default because it needs a real secret. Create it first, then set `monitoring_apply_pve_exporter: true`.

```bash
kubectl -n monitoring create secret generic pve-exporter --from-file=pve.yml
ansible-playbook -i inventory/hosts.yml infrastructure.yml --tags monitoring
```
