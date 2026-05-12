# Local Configuration

This directory centralizes local provisioning configuration.

Create your local file:

```bash
make config-init
```

Then edit:

```text
config/prod.env
```

`config/prod.env` is ignored by Git because it can contain local IPs, Proxmox tokens, SSH keys, and paths to password files.

## What Goes In `prod.env`

- Proxmox endpoint and API token.
- Proxmox node, datastore and cloud-init template IDs.
- VM IP addresses.
- VM CPU, RAM and disk sizes.
- SSH public key injected by cloud-init.
- Kubernetes and platform versions.
- MetalLB, cert-manager, Argo CD, ingress and monitoring switches.
- Optional Ansible Vault password file path.

## WSL Workflow

Run from the repository root in WSL:

```bash
make check
make prod
```

Use the example file for local syntax validation without creating a real production config:

```bash
make CONFIG_FILE=config/prod.env.example check
```

## What Should Stay Encrypted

Application and database passwords should still live in an encrypted secret system:

- Ansible Vault for infrastructure bootstrap secrets.
- SOPS, SealedSecrets or ExternalSecrets for Kubernetes secrets.

`prod.env` is useful as the local entry point, but it should not become a committed secret store.

## Ansible Vault Password File

If you set:

```env
ANSIBLE_VAULT_PASSWORD_FILE=config/.ansible_vault_password
```

the file must contain only the vault password:

```text
my-vault-password
```

On Linux/WSL, make sure the file is not executable:

```bash
chmod 600 config/.ansible_vault_password
```

or use:

```bash
make vault-pass-fix
```

If the file is executable, Ansible treats it as a script and fails with `Exec format error` unless it has a valid shebang.
