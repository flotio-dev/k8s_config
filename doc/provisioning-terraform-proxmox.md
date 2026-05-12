# Provisioning Terraform avec Proxmox

Objectif: arriver a une infra reproductible ou une commande cree les VM Proxmox, puis Ansible installe Kubernetes et les outils plateforme.

```text
Proxmox
  -> Terraform cree les VM, disques, reseau, cloud-init
  -> Ansible installe containerd, kubeadm, Flannel, MetalLB, ingress, cert-manager, Argo CD, monitoring
  -> Argo CD deploie les applications Kubernetes
```

Terraform ne remplace pas Ansible ni Argo CD:

- Terraform gere l'infrastructure IaaS: VM, CPU, RAM, disques, IP, cloud-init.
- Ansible configure les machines: OS, paquets, Kubernetes, outils cluster.
- Argo CD maintient l'etat applicatif dans Kubernetes.

## Provider conseille

Utiliser le provider Terraform `bpg/proxmox`.

Il est plus moderne que l'ancien provider Telmate et expose des ressources Proxmox VE claires comme `proxmox_virtual_environment_vm`, `proxmox_virtual_environment_file`, les disques, le reseau et l'initialisation cloud-init.

Exemple `providers.tf`:

```hcl
terraform {
  required_version = ">= 1.7.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.100"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure = var.proxmox_insecure

  ssh {
    agent = true
  }
}
```

## Configuration Proxmox a faire

### 1. Creer un token API

Dans l'interface Proxmox:

1. Aller dans `Datacenter > Permissions > API Tokens`.
2. Creer un utilisateur dedie, par exemple `terraform@pve`.
3. Creer un token, par exemple `terraform@pve!terraform`.
4. Noter le `Token ID` et le `Secret`.

Le token complet ressemble a:

```text
terraform@pve!terraform=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

Ne jamais commiter ce token dans Git. Le passer via variable d'environnement:

```bash
export TF_VAR_proxmox_api_token='terraform@pve!terraform=xxxxx'
```

Sous PowerShell:

```powershell
$env:TF_VAR_proxmox_api_token = "terraform@pve!terraform=xxxxx"
```

### 2. Donner les permissions

Pour un projet d'ecole ou un homelab, le plus simple est de donner au token le role `PVEVMAdmin` sur le pool ou le noeud utilise.

Minimum recommande:

- `VM.Allocate`
- `VM.Clone`
- `VM.Config.CPU`
- `VM.Config.Memory`
- `VM.Config.Disk`
- `VM.Config.Network`
- `VM.Config.Cloudinit`
- `VM.PowerMgmt`
- `Datastore.AllocateSpace`
- `Datastore.Audit`
- `Sys.Audit`

Pour aller vite au debut, creer un pool Proxmox `flotio-prod`, donner les droits dessus, puis restreindre ensuite.

### 3. Preparer le stockage

Verifier les stockages Proxmox disponibles:

- stockage VM/disques: souvent `local-lvm`, `vmdata`, `ssd`, etc.
- stockage snippets/cloud-init: souvent `local`.

Le stockage qui recoit les fichiers cloud-init doit accepter le contenu `Snippets`.

Dans Proxmox:

1. Aller dans `Datacenter > Storage`.
2. Selectionner le stockage, par exemple `local`.
3. Dans `Content`, activer `Snippets`.

### 4. Preparer un template cloud-init

Terraform peut creer des VM depuis une image cloud, mais pour ton cas le plus simple et stable est:

1. Creer un template Ubuntu Server ou Debian cloud-init dans Proxmox.
2. Installer `qemu-guest-agent` dans le template.
3. Activer l'agent QEMU dans les options de la VM.
4. Nettoyer la machine avant conversion en template.
5. Convertir la VM en template.

Exemple de template:

```text
ubuntu-24.04-cloudinit-template
```

Points importants dans le template:

- cloud-init installe et fonctionnel.
- `qemu-guest-agent` installe.
- disque en SCSI avec controller `VirtIO SCSI`.
- carte reseau `virtio`.
- pas de cle SSH ou d'identite machine definitive dans le template.

## Structure Terraform conseillee

```text
terraform/
  modules/
    proxmox-vm/
      main.tf
      variables.tf
      outputs.tf
  environments/
    prod/
      providers.tf
      main.tf
      variables.tf
      terraform.tfvars.example
      outputs.tf
      templates/
        hosts.yml.tftpl
```

Le module `proxmox-vm` cree une VM generique.

L'environnement `prod` declare les VM reelles:

- `k8s-cp-01`
- `k8s-worker-01`
- `k8s-worker-02`
- `k8s-worker-03`
- Postgres reste pour l'instant deploye dans Kubernetes via les manifests GitOps.

Garage reste sur le mini PC existant.

## Variables Terraform

Exemple `variables.tf`:

```hcl
variable "proxmox_endpoint" {
  type        = string
  description = "URL API Proxmox, ex: https://192.168.1.16:8006/"
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "Token API Proxmox au format user@realm!token=secret"
}

variable "proxmox_insecure" {
  type        = bool
  default     = true
  description = "true si Proxmox utilise un certificat auto-signe"
}

variable "proxmox_node_name" {
  type        = string
  description = "Nom du noeud Proxmox cible"
}

variable "vm_datastore_id" {
  type        = string
  description = "Datastore pour les disques VM"
}

variable "snippet_datastore_id" {
  type        = string
  description = "Datastore Proxmox pour le disque cloud-init. Il doit supporter le contenu images"
}

variable "template_vm_id" {
  type        = number
  description = "ID du template cloud-init"
}

variable "ssh_public_key" {
  type        = string
  description = "Cle SSH publique injectee par cloud-init"
}
```

Dans ce repo, le fichier conseille est `config/prod.env`: il centralise les IP, tailles de VM, endpoint Proxmox, token, cle SSH publique et options Ansible. Le `Makefile` charge ce fichier et exporte les valeurs vers Terraform sous forme de variables `TF_VAR_*`.

Exemple equivalent en `terraform.tfvars.example` si tu veux lancer Terraform directement sans `make`:

```hcl
proxmox_endpoint     = "https://192.168.1.16:8006/"
proxmox_insecure     = true
proxmox_node_name    = "pve"
vm_datastore_id      = "local-lvm"
snippet_datastore_id = "local-lvm"
template_vm_id       = 9000
ssh_public_key       = "ssh-ed25519 AAAA... user@host"
```

## Exemple de VM Proxmox

Exemple simplifie avec `proxmox_virtual_environment_vm`:

```hcl
resource "proxmox_virtual_environment_vm" "k8s_cp_01" {
  name      = "k8s-cp-01"
  node_name = var.proxmox_node_name
  vm_id     = 101

  clone {
    vm_id = var.template_vm_id
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 6144
  }

  disk {
    datastore_id = var.vm_datastore_id
    interface    = "scsi0"
    size         = 60
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  initialization {
    datastore_id = var.snippet_datastore_id

    ip_config {
      ipv4 {
        address = "192.168.1.10/24"
        gateway = "192.168.1.1"
      }
    }

    user_account {
      username = "ansible"
      keys     = [var.ssh_public_key]
    }

    dns {
      servers = ["1.1.1.1", "8.8.8.8"]
    }
  }
}
```

Pour eviter la duplication, mettre cette logique dans `modules/proxmox-vm`, puis passer un objet par VM.

## Dimensionnement cible pour ton infra

Avec le serveur Proxmox 48 CPU / 64 Go RAM / 1 To:

| VM | ID | vCPU | RAM | Disque | Role |
|---|---:|---:|---:|---:|---|
| `k8s-cp-01` | 800 | 4 | 6 Go | 60 Go | Control plane Kubernetes |
| `k8s-worker-01` | 801 | 8 | 12 Go | 120 Go | Apps, API, ingress |
| `k8s-worker-02` | 802 | 8 | 12 Go | 120 Go | Apps, monitoring |
| `k8s-worker-03` | 803 | 8 | 12 Go | 120 Go | Worker generaliste |
Le mini PC reste dedie a Garage/S3:

| Machine | CPU | RAM | Disque | Role |
|---|---:|---:|---:|---|
| Mini PC | 4 | 16 Go | 1 To | Garage/S3, artefacts, backups |

## Generer l'inventaire Ansible

Terraform peut ecrire directement l'inventaire Ansible utilise par `ansible/infrastructure.yml`.

Template `templates/hosts.yml.tftpl`:

```yaml
---
all:
  vars:
    ansible_user: ansible
    ansible_python_interpreter: /usr/bin/python3
  children:
    control_plane:
      hosts:
        ${control_plane.name}:
          ansible_host: ${control_plane.ip}
    workers:
      hosts:
%{ for worker in workers ~}
        ${worker.name}:
          ansible_host: ${worker.ip}
%{ endfor ~}
```

Ressource Terraform:

```hcl
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../../../ansible/inventory/hosts.generated.yml"

  content = templatefile("${path.module}/templates/hosts.yml.tftpl", {
    control_plane = {
      name = "k8s-cp-01"
      ip   = "192.168.1.10"
    }
    workers = [
      {
        name = "k8s-worker-01"
        ip   = "192.168.1.11"
      },
      {
        name = "k8s-worker-02"
        ip   = "192.168.1.12"
      }
    ]
  })
}
```

Ensuite:

```bash
ansible-playbook -i ansible/inventory/hosts.generated.yml ansible/infrastructure.yml --ask-vault-pass
```

## Future evolution: node build dedie

Pour l'instant, les manifests ne ciblent pas un worker build dedie. Les builds tournent donc sur les workers standards.

Quand les manifests ou le backend genereront des Jobs avec `nodeSelector` et `tolerations`, ajouter un worker dedie dans Terraform, puis l'isoler apres bootstrap Kubernetes:

```bash
kubectl label node k8s-build-01 workload=build
kubectl taint node k8s-build-01 workload=build:NoSchedule
```

Les Jobs Android/Flutter devront utiliser:

```yaml
nodeSelector:
  workload: build
tolerations:
  - key: workload
    operator: Equal
    value: build
    effect: NoSchedule
resources:
  requests:
    cpu: "2"
    memory: 4Gi
  limits:
    cpu: "8"
    memory: 12Gi
```

Idealement, ajouter cette etape dans un role Ansible `kubernetes_node_labels`.

## Workflow attendu

Premiere creation:

```bash
cp config/prod.env.example config/prod.env
make tf-init
make tf-plan
make tf-apply
ansible-playbook -i ansible/inventory/hosts.generated.yml ansible/infrastructure.yml --ask-vault-pass
```

Objectif final avec un `Makefile`:

```makefile
prod:
	make tf-init
	make tf-fmt
	make tf-validate
	make tf-apply
	make ansible
```

Puis:

```bash
make prod
```

Pour une vraie prod, eviter `-auto-approve` tant que le projet n'est pas stable.

## Secrets et securite

Ne jamais stocker dans Git:

- token API Proxmox;
- mot de passe Proxmox;
- cle privee SSH;
- secrets Kubernetes;
- mots de passe Postgres;
- credentials Garage/S3.

Utiliser:

- variables d'environnement `TF_VAR_*` pour Terraform;
- `config/prod.env` local ignore par Git;
- `terraform.tfvars` local ignore par Git;
- Ansible Vault pour `ansible/inventory/group_vars/all/vault.yml`;
- ExternalSecrets, SealedSecrets ou SOPS pour les secrets Kubernetes.

Ajouter un `.gitignore`:

```gitignore
terraform/**/.terraform/
terraform/**/*.tfstate
terraform/**/*.tfstate.*
terraform/**/terraform.tfvars
terraform/**/.terraform.lock.hcl
ansible/inventory/hosts.generated.yml
```

Note: `.terraform.lock.hcl` peut etre commit dans une equipe pour pinner les providers. En projet d'ecole solo, tu peux choisir de le garder ou non, mais il faut etre coherent.

## Backend Terraform

Au debut, un state local suffit.

Pour une equipe ou une soutenance plus propre, utiliser un backend distant:

- Terraform Cloud;
- GitLab managed Terraform state;
- bucket S3 compatible Garage avec verrouillage a gerer prudemment.

Pour ton cas, le plus simple:

```text
state local pour la demo
backup du dossier terraform vers Garage
```

## Pieges frequents

- Le stockage cloud-init n'a pas `Snippets` active.
- Le template n'a pas `cloud-init` installe.
- Le template n'a pas `qemu-guest-agent`.
- Le certificat Proxmox est auto-signe et `insecure` vaut `false`.
- L'IP statique Terraform est correcte cote Proxmox mais la VM boote en DHCP a cause du template cloud-init.
- Les VM sont creees, mais Ansible ne peut pas se connecter car la cle SSH n'a pas ete injectee.
- Terraform gere une VM deja modifiee a la main dans Proxmox: risque de drift.

## Definition d'une infra prod en une commande

Pour pouvoir dire "une ligne de commande, une infra prod", il faut que la commande fasse ces etapes:

1. Terraform cree les VM.
2. Terraform genere l'inventaire Ansible.
3. Ansible attend que SSH soit disponible.
4. Ansible bootstrap Kubernetes.
5. Ansible installe les outils plateforme.
6. Argo CD synchronise les applications.
7. Le postflight verifie les noeuds et pods.

Formulation soutenance:

> Le provisioning est automatise par Terraform sur Proxmox. Terraform cree les VM a partir d'un template cloud-init et genere l'inventaire Ansible. Ansible configure ensuite le cluster Kubernetes avec kubeadm et installe les composants plateforme. Une fois Argo CD deploye, les applications sont synchronisees depuis le depot GitOps.

## Sources

- [Provider bpg/proxmox sur Terraform Registry](https://registry.terraform.io/providers/bpg/proxmox/latest)
- [Ressource `proxmox_virtual_environment_vm`](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm)
- [Guide cloud-init du provider bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/guides/cloud-init)
- [Guide cloud image du provider bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest/docs/guides/cloud-image)
