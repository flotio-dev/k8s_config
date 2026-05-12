resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  description = var.description
  node_name   = var.node_name
  vm_id       = var.vm_id
  tags        = var.tags
  started     = var.started
  on_boot     = var.on_boot

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores   = var.cpu_cores
    sockets = var.cpu_sockets
    type    = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_size_gb
    file_format  = "raw"
  }

  network_device {
    bridge  = var.bridge
    model   = "virtio"
    vlan_id = var.vlan_id
  }

  initialization {
    datastore_id = var.snippet_datastore_id

    dns {
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_gateway
      }
    }

    user_account {
      username = var.ci_username
      keys     = var.ssh_public_keys
    }
  }
}
