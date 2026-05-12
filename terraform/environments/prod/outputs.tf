output "vm_addresses" {
  value = {
    for name, vm in local.vms : name => vm.ansible_host
  }
  description = "VM names mapped to their Ansible SSH address."
}

output "ansible_inventory" {
  value       = abspath(local_file.ansible_inventory.filename)
  description = "Generated Ansible inventory path."
}

output "next_command" {
  value       = "ansible-playbook -i ${abspath(local_file.ansible_inventory.filename)} ansible/infrastructure.yml --ask-vault-pass"
  description = "Command to bootstrap Kubernetes after Terraform apply."
}
