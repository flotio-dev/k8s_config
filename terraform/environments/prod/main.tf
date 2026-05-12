locals {
  vms = {
    "k8s-cp-01" = {
      vm_id        = var.k8s_cp_01_vm_id
      role         = "control_plane"
      ipv4_address = var.k8s_cp_01_ip_cidr
      ansible_host = split("/", var.k8s_cp_01_ip_cidr)[0]
      cpu_cores    = var.k8s_cp_01_cpu
      memory_mb    = var.k8s_cp_01_memory_mb
      disk_size_gb = var.k8s_cp_01_disk_gb
      tags         = ["flotio", "kubernetes", "control-plane"]
    }

    "k8s-worker-01" = {
      vm_id        = var.k8s_worker_01_vm_id
      role         = "worker"
      ipv4_address = var.k8s_worker_01_ip_cidr
      ansible_host = split("/", var.k8s_worker_01_ip_cidr)[0]
      cpu_cores    = var.k8s_worker_01_cpu
      memory_mb    = var.k8s_worker_01_memory_mb
      disk_size_gb = var.k8s_worker_01_disk_gb
      tags         = ["flotio", "kubernetes", "worker"]
    }

    "k8s-worker-02" = {
      vm_id        = var.k8s_worker_02_vm_id
      role         = "worker"
      ipv4_address = var.k8s_worker_02_ip_cidr
      ansible_host = split("/", var.k8s_worker_02_ip_cidr)[0]
      cpu_cores    = var.k8s_worker_02_cpu
      memory_mb    = var.k8s_worker_02_memory_mb
      disk_size_gb = var.k8s_worker_02_disk_gb
      tags         = ["flotio", "kubernetes", "worker"]
    }

    "k8s-worker-03" = {
      vm_id        = var.k8s_worker_03_vm_id
      role         = "worker"
      ipv4_address = var.k8s_worker_03_ip_cidr
      ansible_host = split("/", var.k8s_worker_03_ip_cidr)[0]
      cpu_cores    = var.k8s_worker_03_cpu
      memory_mb    = var.k8s_worker_03_memory_mb
      disk_size_gb = var.k8s_worker_03_disk_gb
      tags         = ["flotio", "kubernetes", "worker"]
    }

  }

  control_plane_hosts = [
    for name, vm in local.vms : {
      name = name
      ip   = vm.ansible_host
    } if vm.role == "control_plane"
  ]

  worker_hosts = [
    for name, vm in local.vms : {
      name = name
      ip   = vm.ansible_host
    } if vm.role == "worker"
  ]
}

module "vm" {
  source   = "../../modules/proxmox-vm"
  for_each = local.vms

  name                 = each.key
  description          = "flotio ${each.value.role} node managed by Terraform"
  node_name            = var.proxmox_node_name
  vm_id                = each.value.vm_id
  template_vm_id       = var.template_vm_id
  datastore_id         = var.vm_datastore_id
  snippet_datastore_id = var.snippet_datastore_id
  bridge               = var.vm_bridge
  vlan_id              = var.vm_vlan_id
  cpu_cores            = each.value.cpu_cores
  memory_mb            = each.value.memory_mb
  disk_size_gb         = each.value.disk_size_gb
  ipv4_address         = each.value.ipv4_address
  ipv4_gateway         = var.ipv4_gateway
  dns_servers          = var.dns_servers
  ci_username          = var.ci_username
  ssh_public_keys      = [var.ssh_public_key]
  tags                 = each.value.tags
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/${var.ansible_inventory_path}"

  content = templatefile("${path.module}/templates/hosts.yml.tftpl", {
    ansible_user        = var.ci_username
    control_plane_hosts = local.control_plane_hosts
    worker_hosts        = local.worker_hosts
  })
}
