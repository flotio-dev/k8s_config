variable "proxmox_endpoint" {
  type        = string
  description = "Proxmox API URL, for example https://192.168.1.16:8006/."
}

variable "proxmox_api_token" {
  type        = string
  sensitive   = true
  description = "Proxmox API token, format user@realm!token=secret."
}

variable "proxmox_insecure" {
  type        = bool
  default     = true
  description = "Set true when Proxmox uses a self-signed certificate."
}

variable "proxmox_node_name" {
  type        = string
  description = "Target Proxmox node name."
}

variable "template_vm_id" {
  type        = number
  description = "Cloud-init template VM ID."
}

variable "vm_datastore_id" {
  type        = string
  description = "Datastore for VM disks."
}

variable "snippet_datastore_id" {
  type        = string
  description = "Datastore used for the cloud-init disk. It must support Proxmox content type images."
}

variable "vm_bridge" {
  type        = string
  default     = "vmbr0"
  description = "Proxmox network bridge."
}

variable "vm_vlan_id" {
  type        = number
  default     = null
  description = "Optional VLAN ID for all VMs."
}

variable "ipv4_gateway" {
  type        = string
  description = "Default IPv4 gateway."
}

variable "dns_servers" {
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
  description = "DNS servers injected by cloud-init."
}

variable "ci_username" {
  type        = string
  default     = "ansible"
  description = "Cloud-init user used by Ansible."
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key injected by cloud-init."
}

variable "k8s_cp_01_vm_id" {
  type        = number
  default     = 800
  description = "k8s-cp-01 Proxmox VM ID."
}

variable "k8s_worker_01_vm_id" {
  type        = number
  default     = 801
  description = "k8s-worker-01 Proxmox VM ID."
}

variable "k8s_worker_02_vm_id" {
  type        = number
  default     = 802
  description = "k8s-worker-02 Proxmox VM ID."
}

variable "k8s_worker_03_vm_id" {
  type        = number
  default     = 803
  description = "k8s-worker-03 Proxmox VM ID."
}

variable "k8s_cp_01_ip_cidr" {
  type        = string
  default     = "192.168.1.10/24"
  description = "k8s-cp-01 IPv4 address with CIDR."
}

variable "k8s_worker_01_ip_cidr" {
  type        = string
  default     = "192.168.1.11/24"
  description = "k8s-worker-01 IPv4 address with CIDR."
}

variable "k8s_worker_02_ip_cidr" {
  type        = string
  default     = "192.168.1.12/24"
  description = "k8s-worker-02 IPv4 address with CIDR."
}

variable "k8s_worker_03_ip_cidr" {
  type        = string
  default     = "192.168.1.13/24"
  description = "k8s-worker-03 IPv4 address with CIDR."
}

variable "k8s_cp_01_cpu" {
  type        = number
  default     = 4
  description = "k8s-cp-01 vCPU count."
}

variable "k8s_cp_01_memory_mb" {
  type        = number
  default     = 6144
  description = "k8s-cp-01 memory in MiB."
}

variable "k8s_cp_01_disk_gb" {
  type        = number
  default     = 60
  description = "k8s-cp-01 disk size in GiB."
}

variable "k8s_worker_01_cpu" {
  type        = number
  default     = 8
  description = "k8s-worker-01 vCPU count."
}

variable "k8s_worker_01_memory_mb" {
  type        = number
  default     = 12288
  description = "k8s-worker-01 memory in MiB."
}

variable "k8s_worker_01_disk_gb" {
  type        = number
  default     = 120
  description = "k8s-worker-01 disk size in GiB."
}

variable "k8s_worker_02_cpu" {
  type        = number
  default     = 8
  description = "k8s-worker-02 vCPU count."
}

variable "k8s_worker_02_memory_mb" {
  type        = number
  default     = 12288
  description = "k8s-worker-02 memory in MiB."
}

variable "k8s_worker_02_disk_gb" {
  type        = number
  default     = 120
  description = "k8s-worker-02 disk size in GiB."
}

variable "k8s_worker_03_cpu" {
  type        = number
  default     = 8
  description = "k8s-worker-03 vCPU count."
}

variable "k8s_worker_03_memory_mb" {
  type        = number
  default     = 12288
  description = "k8s-worker-03 memory in MiB."
}

variable "k8s_worker_03_disk_gb" {
  type        = number
  default     = 120
  description = "k8s-worker-03 disk size in GiB."
}

variable "ansible_inventory_path" {
  type        = string
  default     = "../../../ansible/inventory/hosts.generated.yml"
  description = "Path where Terraform writes the generated Ansible inventory."
}
