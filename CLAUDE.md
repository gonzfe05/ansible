# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ansible playbooks and roles for automated development environment setup after a fresh Ubuntu installation. Creates a user `aleph` and configures development tools, shell environment, and cloud integrations.

## Essential Commands

### Testing (Always Test First)
```bash
make test-vm-syntax     # Quick syntax check (5 seconds)
make test-vm-core       # Core roles in VM (5-10 min)
make test-vm            # Full playbook in ephemeral VM
make test               # Molecule tests for all roles
```

### Running
```bash
make run_local                              # Run on localhost
make run_local vault_pass_file=~/.vault_pass.txt  # With vault password
```

### Development Setup
```bash
make install_dev        # Install Docker, Ansible, and Molecule
```

### Individual Role Testing
```bash
cd playbooks/roles/<role_name>
molecule test           # Full test cycle
molecule converge       # Apply role only (faster iteration)
molecule verify         # Run verification tests
molecule destroy        # Clean up test container
```

## Architecture

### Main Playbook Structure
The primary playbook `playbooks/after_format.yaml` orchestrates 16 roles with specific privilege escalation patterns:
- **Root roles**: `apt_installs`, `users`, `vscode`, `go`, `python`, `R`
- **User roles** (become_user: aleph): `ssh`, `env_setup`, `dotfiles`, `node`, `aws`, `snowflake`, `repos`, `obsidian`, `astro_cli`, `ngrok`
- **Mixed**: `x11_auth` (become: true, runs as root but configures for aleph)

### Tag System
Selective execution via tags:
- `core` - Essential setup (apt_installs, users, x11_auth, ssh, env_setup, dotfiles, vscode, node)
- `aws`, `snowflake`, `projects`, `go`, `python`, `R`, `obsidian`, `astro`, `ngrok`

### Role Standard Structure
```
playbooks/roles/<role_name>/
├── tasks/main.yml       # Required: role tasks
├── defaults/main.yml    # Optional: default variables
├── vars/main.yml        # Optional: role variables
├── handlers/main.yml    # Optional: handlers (e.g., restart services)
├── files/               # Optional: static files
├── molecule/default/    # Required for testable roles
│   ├── molecule.yml
│   ├── converge.yml
│   └── verify.yml
└── README.md
```

### Molecule Testing
Uses Docker driver with `geerlingguy/docker-ubuntu${UBUNTU_MAJOR:-24}${UBUNTU_MINOR:-04}-ansible` images. Test sequence: dependency → create → prepare → converge → verify → destroy.

## Key Patterns

### Privilege Escalation
Roles use `become: true` with specific `become_user`. The `allow_world_readable_tmpfiles = True` in ansible.cfg is required for becoming unprivileged users.

### Vault-Encrypted Secrets
Credentials are vault-encrypted. Files requiring encryption:
- `playbooks/roles/ssh/files/id_rsa`
- `playbooks/roles/aws/files/aws_credentials.yml`
- `playbooks/roles/ngrok/files/ngrok_credentials.yml`

### User Safeguard
The Makefile blocks execution by the `aleph` user to prevent circular dependency issues (aleph is created by this repository).

## Common Workflows

### Adding a New Role
1. Create role structure in `playbooks/roles/<name>/`
2. Add molecule tests in `molecule/default/`
3. Test with `molecule test`
4. Add to `after_format.yaml` with appropriate tags and become_user
5. Document in role README.md

### Modifying Existing Roles
1. Run `make test-vm-syntax` to verify playbook validity
2. Test the specific role: `cd playbooks/roles/<role> && molecule test`
3. Test full playbook: `make test-vm-core` or `make test-vm`

### Skip Problematic Roles
```bash
ansible-playbook playbooks/after_format.yaml --skip-tags aws,repos,ngrok
```
