# VM-Based Playbook Testing

This document describes how to test the `after_format.yaml` playbook (or any playbook) in an isolated ephemeral VM before running it on your local machine.

## Why Test in a VM?

- **Safety**: Test destructive changes without affecting your host system
- **Repeatability**: Start fresh every time with a clean Ubuntu installation
- **Systemd support**: Unlike Docker, VMs have full systemd support (SSH daemon, services, etc.)
- **End-to-end validation**: Test the complete playbook flow including service management

## Prerequisites

The script will automatically install Multipass if it's not present. On Linux, this requires `snap`:

```bash
# Ubuntu/Debian
sudo apt install snapd

# Then the script will install multipass via snap
```

Or install Multipass manually: https://multipass.run/install

## Quick Start

### 1. Syntax Check (Fast, Local)

Before launching a VM, verify your playbook syntax:

```bash
make test-vm-syntax
```

This will:
- Check playbook syntax
- List all available tags
- Show all tasks that would run

### 2. Full Playbook Test (Recommended)

Run the complete `after_format.yaml` playbook in an ephemeral VM:

```bash
make test-vm
```

This will:
1. Install Multipass (if needed)
2. Create a fresh Ubuntu VM
3. Transfer your ansible repository
4. Install dependencies (ansible, git, python3)
5. Run `playbooks/after_format.yaml`
6. Clean up the VM after success

**The VM is automatically destroyed after a successful run.**

### 3. Core Tags Only (Faster)

Test only the core roles (skip projects, aws, ngrok, etc.):

```bash
make test-vm-core
```

This runs with:
- `--tags core`
- `-e ssh_server_enabled=false` (skip SSH server setup)

### 4. Keep VM for Debugging

If you want to inspect the VM after the playbook runs:

```bash
make test-vm-keep
```

After the playbook completes, the VM stays running. You can:

```bash
# Shell into the VM
multipass shell ansible-test

# Check status
multipass info ansible-test

# When done, clean up manually
multipass delete ansible-test && multipass purge
```

## Configuration

### Customize VM Resources

```bash
# Use more CPUs/RAM
make test-vm vm_cpus=4 vm_mem=8G

# Larger disk
make test-vm vm_disk=40G

# Different Ubuntu version
make test-vm ubuntu_major=22 ubuntu_minor=04
```

### Custom VM Name

```bash
make test-vm vm_name=my-test-vm
```

### Vault Passwords

If your playbook requires vault-encrypted files (like SSH keys):

```bash
# Method 1: Using environment variable (recommended)
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm

# Method 2: Using make variable
make test-vm vault_pass_file=~/.vault_pass.txt

# Method 3: Using absolute path
make test-vm vault_pass_file=/home/user/.vault_password

# Works with all test targets
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm-core
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm-keep
```

The vault password file will be securely transferred to the VM and used for decryption.

### Custom Playbook or Extra Args

Use the script directly for advanced options:

```bash
# Test a different playbook
PLAYBOOK=playbooks/remote_ssh_server.yaml scripts/test_vm.sh

# Pass extra ansible-playbook arguments
EXTRA_ARGS="--tags ssh,vscode --skip-tags repos" scripts/test_vm.sh

# Combine multiple options
VM_NAME=debug-vm \
  KEEP_VM=true \
  PLAYBOOK=playbooks/just_cuda.yaml \
  EXTRA_ARGS="--check" \
  scripts/test_vm.sh
```

## Environment Variables

The `scripts/test_vm.sh` script accepts these environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `VM_NAME` | `ansible-test` | Name of the Multipass VM |
| `VM_CPUS` | `2` | Number of CPUs |
| `VM_MEM` | `4G` | Memory allocation |
| `VM_DISK` | `20G` | Disk size |
| `UBUNTU_VERSION` | `24.04` | Ubuntu version to use |
| `PLAYBOOK` | `playbooks/after_format.yaml` | Playbook to run |
| `EXTRA_ARGS` | _(empty)_ | Extra arguments for `ansible-playbook` |
| `VAULT_PASS_FILE` | _(empty)_ | Path to vault password file |
| `KEEP_VM` | `false` | Keep VM after run (`true`/`false`) |

## Workflow Examples

### Pre-flight before running locally

1. Check syntax:
   ```bash
   make test-vm-syntax
   ```

2. Test core functionality:
   ```bash
   make test-vm-core
   ```

3. Test full playbook:
   ```bash
   make test-vm
   ```

4. If everything passes, run locally:
   ```bash
   make run_local
   ```

### Debugging a failing playbook

1. Run with VM kept:
   ```bash
   make test-vm-keep
   ```

2. Shell into the VM:
   ```bash
   multipass shell ansible-test
   ```

3. Inspect logs, files, services:
   ```bash
   # Check service status
   systemctl status ssh

   # View logs
   journalctl -u ssh

   # Check files
   cat ~/.ssh/config
   ls -la ~/.ssh/
   ```

4. Re-run the playbook inside the VM:
   ```bash
   cd /home/ubuntu/ansible
   ansible-playbook playbooks/after_format.yaml --tags specific-tag
   ```

5. Clean up when done:
   ```bash
   multipass delete ansible-test && multipass purge
   ```

### Testing specific roles or tags

```bash
# Test only SSH and VSCode setup
EXTRA_ARGS="--tags ssh,vscode" scripts/test_vm.sh

# Skip certain roles
EXTRA_ARGS="--skip-tags repos,aws,ngrok" scripts/test_vm.sh

# Dry-run (check mode)
EXTRA_ARGS="--check --diff" scripts/test_vm.sh

# Verbose output
EXTRA_ARGS="-vv" scripts/test_vm.sh
```

## Known Issues

### SSH Role Requirements

The `ssh` role expects these files:
- `playbooks/roles/ssh/files/id_rsa` (vault-encrypted private key)
- `playbooks/roles/ssh/files/id_rsa.pub`

If these are missing, the playbook will fail. Solutions:

1. **Provide the keys**: Place your SSH keys in the expected location
2. **Skip SSH setup**: `EXTRA_ARGS="--skip-tags ssh" scripts/test_vm.sh`
3. **Generate keys on-the-fly**: Modify the `ssh` role to generate keys if missing

### Repos Role Requirements

The `repos` role clones private GitHub repositories via SSH. This requires:
- Valid SSH keys (from the `ssh` role)
- The public key registered in your GitHub account

To test without repos:
```bash
EXTRA_ARGS="--skip-tags repos" scripts/test_vm.sh
```

### AWS/ngrok Roles Requirements

These roles require credentials. Skip them if not needed:
```bash
EXTRA_ARGS="--skip-tags aws,ngrok" scripts/test_vm.sh
```

## Troubleshooting

### Multipass installation fails

**Linux**: Ensure `snapd` is installed and running:
```bash
sudo apt install snapd
sudo systemctl start snapd
```

**macOS**: Install via Homebrew or download from https://multipass.run/install

### VM fails to launch

Check Multipass status:
```bash
multipass version
multipass list
```

Check system logs:
```bash
snap logs multipass  # Linux
```

### Playbook fails in VM

The VM remains accessible if you used `make test-vm-keep`. Shell in and debug:
```bash
multipass shell ansible-test
cd /home/ubuntu/ansible
# Debug here
```

### Cleanup stuck VMs

```bash
# List all VMs
multipass list

# Force delete
multipass delete --purge ansible-test

# Purge all deleted VMs
multipass purge
```

## Tips

- Run `make test-vm-syntax` first - it's instant and catches obvious errors
- Use `make test-vm-core` for rapid iteration during development
- Keep VMs for debugging with `make test-vm-keep`
- Test incrementally with `--tags` to isolate issues
- The full `make test-vm` is your final validation before running locally

## See Also

- [CONFIG.md](CONFIG.md) - Main configuration guide
- [REMOTE_SSH_SETUP.md](playbooks/REMOTE_SSH_SETUP.md) - SSH server setup
- [makefile](makefile) - All available make targets

