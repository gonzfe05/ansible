# Ansible Development Environment Setup

This repository contains Ansible playbooks and roles to automate the setup of a complete development environment after a fresh OS installation.

## Quick Start

### 1. Install Prerequisites

```bash
make install      # Install Docker and Ansible
make install_dev  # Also install Molecule for role testing
```

### 2. Test Before Running

**Recommended**: Test the playbook in an isolated VM before running on your machine:

```bash
# Quick syntax check (5 seconds)
make test-vm-syntax

# Test core functionality in VM (5-10 min)
make test-vm-core

# Full end-to-end test in VM (10-20 min)
make test-vm
```

See [TESTING_QUICK_REFERENCE.md](TESTING_QUICK_REFERENCE.md) for all testing options.

### 3. Run Locally

After testing in VM, run on your local machine:

```bash
make run_local
```

## Main Playbooks

### `after_format.yaml` - Complete Development Environment

Sets up a full development environment with:
- **Core System**: Users, SSH, shell (zsh), dotfiles, VSCode
- **Development Tools**: Node.js, Python, Go, R
- **Applications**: Obsidian, Astro CLI
- **Cloud Tools**: AWS CLI, ngrok
- **Projects**: Clone personal repositories

Run with:
```bash
ansible-playbook playbooks/after_format.yaml --ask-vault-pass --ask-become-pass
```

Or with tags to install specific components:
```bash
# Core only (users, ssh, shell, dotfiles, vscode, node)
ansible-playbook playbooks/after_format.yaml --tags core --ask-become-pass

# Add Python and Go
ansible-playbook playbooks/after_format.yaml --tags core,python,go --ask-become-pass

# Everything except AWS and repos
ansible-playbook playbooks/after_format.yaml --skip-tags aws,repos --ask-become-pass
```

### `remote_ssh_server.yaml` - Remote SSH Server Setup

Configures SSH server for remote development (VSCode/Cursor) with optional ngrok tunneling.

```bash
ansible-playbook playbooks/remote_ssh_server.yaml
```

### CUDA Playbooks

- `just_cuda.yaml` - CUDA toolkit only
- `just_cuda_container_toolkit.yaml` - CUDA + Docker container runtime
- `container.yaml` - Docker/container setup

## Testing

### Test Individual Roles (Molecule)

```bash
# Test all roles
make test

# Clean test cache
make clean-test-cache
```

### Test Full Playbook in VM

See [VM_TESTING.md](VM_TESTING.md) for complete guide.

Quick commands:
```bash
make test-vm-syntax  # Syntax check + show structure
make test-vm-core    # Core roles only in VM
make test-vm         # Full playbook in ephemeral VM
make test-vm-keep    # Keep VM for debugging
```

Customize VM resources:
```bash
make test-vm vm_cpus=4 vm_mem=8G vm_disk=40G
```

## Available Make Targets

| Target | Description |
|--------|-------------|
| `make install` | Install Docker and Ansible |
| `make install_dev` | Install Docker, Ansible, and Molecule |
| `make run_local` | Run `after_format.yaml` on localhost |
| `make run` | Run playbook in Docker container |
| `make test` | Test all roles with Molecule |
| `make test-vm-syntax` | Quick syntax check and structure display |
| `make test-vm-core` | Test core roles in VM |
| `make test-vm` | Full playbook test in ephemeral VM |
| `make test-vm-keep` | Full test, keep VM for debugging |
| `make clean-test-cache` | Clean Molecule test cache |

## Project Structure

```
.
├── playbooks/
│   ├── after_format.yaml          # Main development environment setup
│   ├── remote_ssh_server.yaml     # SSH server for remote development
│   ├── roles/                     # Ansible roles
│   │   ├── apt_installs/          # Package installation
│   │   ├── users/                 # User management
│   │   ├── ssh/                   # SSH client/server setup
│   │   ├── env_setup/             # Shell environment (zsh, oh-my-zsh)
│   │   ├── dotfiles/              # Dotfiles management with stow
│   │   ├── vscode/                # VSCode CLI installation
│   │   ├── node/                  # Node.js via nvm
│   │   ├── python/                # Python installation
│   │   ├── go/                    # Go installation
│   │   ├── R/                     # R installation
│   │   ├── aws/                   # AWS CLI setup
│   │   ├── repos/                 # Clone Git repositories
│   │   ├── obsidian/              # Obsidian note-taking app
│   │   ├── astro_cli/             # Astronomer CLI
│   │   └── ngrok/                 # ngrok tunneling
│   └── ...
├── scripts/
│   ├── test_vm.sh                 # VM-based testing script
│   ├── test_all_roles.sh          # Molecule testing
│   ├── run_container.sh           # Docker-based execution
│   └── ...
├── makefile                       # Build automation
└── credentials/                   # Vault-encrypted credentials
```

## Configuration

### Vault-Encrypted Secrets

Some roles require encrypted credentials:

```bash
# Create vault password file
echo "your-vault-password" > .vault_password
chmod 600 .vault_password

# Encrypt credentials
ansible-vault encrypt playbooks/roles/ssh/files/id_rsa
ansible-vault encrypt playbooks/roles/ngrok/files/ngrok_credentials.yml
ansible-vault encrypt playbooks/roles/aws/files/aws_credentials.yml

# Run with vault
make run_local vault_pass_file=.vault_password
```

### Customizing Variables

Edit role defaults in `playbooks/roles/*/defaults/main.yml` or override in playbook:

```yaml
- role: ssh
  vars:
    ssh_server_enabled: false  # Disable SSH server
```

## Role-Specific Documentation

Each role has its own README:
- [apt_installs](playbooks/roles/apt_installs/README.md)
- [aws](playbooks/roles/aws/README.md)
- [dotfiles](playbooks/roles/dotfiles/README.md)
- [env_setup](playbooks/roles/env_setup/README.md)
- [go](playbooks/roles/go/README.md)
- [ngrok](playbooks/roles/ngrok/README.md)
- [node](playbooks/roles/node/README.md)
- [obsidian](playbooks/roles/obsidian/README.md)
- [python](playbooks/roles/python/README.md)
- [R](playbooks/roles/R/README.md)
- [repos](playbooks/roles/repos/README.md)
- [shell](playbooks/roles/shell/README.md)
- [ssh](playbooks/roles/ssh/README.md) ([Quick Start](playbooks/roles/ssh/QUICK_START.md))
- [users](playbooks/roles/users/README.md)
- [vscode](playbooks/roles/vscode/README.md)

## Additional Documentation

- [VM_TESTING.md](VM_TESTING.md) - Complete VM testing guide
- [TESTING_QUICK_REFERENCE.md](TESTING_QUICK_REFERENCE.md) - Quick testing commands
- [CONFIG.md](CONFIG.md) - Configuration guide
- [REMOTE_SSH_SETUP.md](playbooks/REMOTE_SSH_SETUP.md) - SSH server setup guide
- [ZSH_AUTOENV_GUIDE.md](ZSH_AUTOENV_GUIDE.md) - Zsh autoenv guide
- [SSH_AGENT_FIX_SUMMARY.md](SSH_AGENT_FIX_SUMMARY.md) - SSH agent troubleshooting
- [ISSUE_3_X11_CLIPBOARD_FIX.md](ISSUE_3_X11_CLIPBOARD_FIX.md) - X11 authorization and clipboard fix

## Troubleshooting

### X11 Authorization and Clipboard Issues

**Problem**: When switching to the `aleph` user, clipboard operations fail or GUI apps won't launch.

**Symptoms**:
- Vim clipboard (`v` + `y`) doesn't copy to system clipboard
- `xclip` fails with "Authorization required" or "Can't open display"
- VSCode won't launch with "Missing X server" error

**Solution**: This is now automatically fixed by the `x11_auth` role in the playbook.

**Manual fix** (if needed immediately):
```bash
# As the graphical session owner (not aleph)
xhost +si:localuser:aleph
```

See [ISSUE_3_X11_CLIPBOARD_FIX.md](ISSUE_3_X11_CLIPBOARD_FIX.md) for complete details.

### SSH Role Issues

The `ssh` role requires:
- `playbooks/roles/ssh/files/id_rsa` (vault-encrypted)
- `playbooks/roles/ssh/files/id_rsa.pub`

To skip: `--skip-tags ssh` or `-e ssh_server_enabled=false`

### Repos Role Issues

Requires SSH keys registered in GitHub. To skip: `--skip-tags repos`

### AWS/ngrok Roles

Require credentials. To skip: `--skip-tags aws,ngrok`

### VM Testing Issues

See [VM_TESTING.md](VM_TESTING.md) troubleshooting section.

## Contributing

1. Test changes with Molecule: `make test`
2. Test full playbook in VM: `make test-vm`
3. Document changes in role README
4. Commit and push

## License

Personal development environment setup - use at your own risk.

