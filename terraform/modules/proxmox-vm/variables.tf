variable "name" {
  type        = string
  description = "VM name."
}

variable "description" {
  type        = string
  default     = null
  description = "Optional VM description."
}

variable "node_name" {
  type        = string
  description = "Target Proxmox node name."
}

variable "vm_id" {
  type        = number
  description = "Proxmox VM ID."
}

variable "template_vm_id" {
  type        = number
  description = "Cloud-init template VM ID used as clone source."
}

variable "datastore_id" {
  type        = string
  description = "Datastore used for the VM disk."
}

variable "snippet_datastore_id" {
  type        = string
  description = "Datastore used for the cloud-init disk. It must support Proxmox content type images."
}

variable "bridge" {
  type        = string
  default     = "vmbr0"
  description = "Network bridge."
}

variable "vlan_id" {
  type        = number
  default     = null
  description = "Optional VLAN ID."
}

variable "cpu_cores" {
  type        = number
  description = "Number of vCPU cores."
}

variable "cpu_sockets" {
  type        = number
  default     = 1
  description = "Number of CPU sockets."
}

variable "memory_mb" {
  type        = number
  description = "Dedicated memory in MiB."
}

variable "disk_size_gb" {
  type        = number
  description = "Main disk size in GiB."
}

variable "ipv4_address" {
  type        = string
  description = "Static IPv4 address with CIDR, for example 192.168.1.10/24."
}

variable "ipv4_gateway" {
  type        = string
  description = "IPv4 gateway."
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

variable "ssh_public_keys" {
  type        = list(string)
  description = "SSH public keys injected for the cloud-init user."
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "Proxmox tags."
}

variable "started" {
  type        = bool
  default     = true
  description = "Start the VM after creation."
}

variable "on_boot" {
  type        = bool
  default     = true
  description = "Start the VM when Proxmox boots."
}
