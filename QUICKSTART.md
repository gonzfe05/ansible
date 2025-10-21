# Quick Start Guide

Get started with this Ansible repository in 5 minutes.

## For the Impatient

```bash
# Clone and enter
git clone <your-repo-url>
cd ansible

# Test before running (RECOMMENDED!)
make test-vm-syntax    # 5 seconds - syntax check
make test-vm-core      # 5-10 min - test in VM

# With vault password (if you have encrypted files)
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm-core

# Run locally when tests pass
make run_local         # Full setup on your machine
```

## Step-by-Step First Run

### 1. Prerequisites (One-Time Setup)

```bash
# Install Docker and Ansible
make install

# For role development (optional)
make install_dev
```

### 2. Test Your Playbook (Before Running Locally!)

The safest approach:

```bash
# Step 1: Quick syntax check (instant)
make test-vm-syntax

# Step 2: Test core functionality in an isolated VM (5-10 min)
make test-vm-core

# Step 3: Full end-to-end test in VM (10-20 min)
make test-vm
```

**What happens**: A fresh Ubuntu VM is created, your playbook runs in isolation, and the VM is automatically cleaned up. Your local machine is never touched.

### 3. Run Locally

Once VM tests pass:

```bash
make run_local
```

You'll be prompted for:
- Ansible vault password (if you have encrypted files)
- Sudo password (for system changes)

## What Gets Installed

The `after_format.yaml` playbook installs:

### Core (tag: `core`)
- ✅ System users and sudo configuration
- ✅ SSH client + server (configurable)
- ✅ Zsh + Oh-My-Zsh + plugins
- ✅ Dotfiles (via stow)
- ✅ VSCode CLI
- ✅ Node.js (via nvm)

### Optional (with tags)
- `python` - Python interpreter
- `go` - Go programming language
- `R` - R programming language
- `aws` - AWS CLI + credentials
- `repos` - Clone your Git repositories
- `obsidian` - Obsidian note-taking app
- `astro` - Astronomer CLI
- `ngrok` - ngrok tunneling

## Selective Installation

Don't want everything? Use tags:

```bash
# Core only
ansible-playbook playbooks/after_format.yaml --tags core --ask-become-pass

# Core + Python + Go
ansible-playbook playbooks/after_format.yaml --tags core,python,go --ask-become-pass

# Everything except repos and aws
ansible-playbook playbooks/after_format.yaml --skip-tags repos,aws --ask-become-pass
```

## Common First-Run Issues

### Issue: SSH key files missing

**Error**: `Could not find or access 'playbooks/roles/ssh/files/id_rsa'`

**Solution**: 
```bash
# Option 1: Skip SSH setup
ansible-playbook playbooks/after_format.yaml --skip-tags ssh --ask-become-pass

# Option 2: Provide SSH keys (see SSH Role documentation)
```

### Issue: GitHub repositories fail to clone

**Error**: `Permission denied (publickey)` when cloning repos

**Solution**: Skip repos during first run:
```bash
ansible-playbook playbooks/after_format.yaml --skip-tags repos --ask-become-pass
```

Then manually set up SSH keys for GitHub and run again with `--tags repos`.

### Issue: Vault password errors

**Error**: `A vault password or secret must be specified to decrypt`

**Solution 1**: Provide vault password file:
```bash
# For VM testing
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm-core

# For local run
make run_local vault_pass_file=~/.vault_pass.txt
```

**Solution 2**: Skip roles with encrypted files:
```bash
ansible-playbook playbooks/after_format.yaml --skip-tags ssh,aws,ngrok --ask-become-pass
```

## Testing Individual Roles

Want to test one role at a time?

```bash
# Test all roles with Molecule
make test

# Test specific role
cd playbooks/roles/ssh
molecule test
```

## VM Testing Commands

Quick reference:

| Command | What It Does | Time |
|---------|-------------|------|
| `make test-vm-syntax` | Syntax check + list tasks | 5 sec |
| `make test-vm-core` | Test core roles in VM | 5-10 min |
| `make test-vm` | Full playbook in VM (auto-cleanup) | 10-20 min |
| `make test-vm-keep` | Full test, keep VM for debugging | 10-20 min |

**Customize VM resources:**
```bash
make test-vm vm_cpus=4 vm_mem=8G vm_disk=40G
```

**Debug inside VM:**
```bash
make test-vm-keep
multipass shell ansible-test
# Debug...
exit
multipass delete ansible-test && multipass purge
```

## Recommended Workflow

### For First-Time Users
1. `make test-vm-syntax` - Validate playbook (instant)
2. `make test-vm-core` - Test core setup safely (5-10 min)
3. `make run_local` - Run on your machine when confident

### For Developers
1. Make changes to roles
2. `molecule test` - Test changed role (fast)
3. `make test-vm-core` - Test in VM context
4. `make test-vm` - Full validation before commit

### For Production Deployment
1. `make test-vm-syntax` - Quick validation
2. `make test` - Test all roles individually
3. `make test-vm` - Full end-to-end test
4. `make run_local` - Deploy when all green

## Need More Help?

- **Quick commands**: [TESTING_QUICK_REFERENCE.md](TESTING_QUICK_REFERENCE.md)
- **VM testing details**: [VM_TESTING.md](VM_TESTING.md)
- **Usage examples**: [USAGE_EXAMPLE.md](USAGE_EXAMPLE.md)
- **Full documentation**: [README.md](README.md)

## Next Steps

Once you're comfortable with the basics:

1. **Customize roles** - Edit `playbooks/roles/*/defaults/main.yml`
2. **Add your repos** - Update `playbooks/roles/repos/vars/main.yml`
3. **Configure secrets** - Set up vault-encrypted credentials
4. **Create new roles** - `ansible-galaxy init playbooks/roles/newrole`
5. **Automate more** - Add tasks to existing roles

## Support

- Check documentation in the repo root
- Review role-specific READMEs in `playbooks/roles/*/README.md`
- Look at `USAGE_EXAMPLE.md` for common scenarios

---

**Remember**: Always test in a VM first with `make test-vm` before running on your local machine!

