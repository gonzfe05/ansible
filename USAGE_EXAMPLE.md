# Usage Examples

Real-world examples of how to use this Ansible repository.

## Scenario 1: Fresh Ubuntu Installation (Complete Setup)

You just installed Ubuntu and want to set up your entire development environment.

```bash
# 1. Clone this repo
git clone git@github.com:yourusername/ansible.git
cd ansible

# 2. Install prerequisites
make install_dev

# 3. Create vault password file (if you have encrypted files)
echo "your-vault-password" > ~/.vault_pass.txt
chmod 600 ~/.vault_pass.txt

# 4. Test in VM first (RECOMMENDED)
make test-vm-syntax    # Quick check (5 sec)

# Test with vault password
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm-core

# 5. If all tests pass, run locally
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make run_local
# OR
make run_local vault_pass_file=~/.vault_pass.txt
```

**Result**: Complete development environment with users, SSH, zsh, dotfiles, VSCode, Node.js, and all configured tools.

---

## Scenario 2: Selective Installation (Only What You Need)

You already have some tools installed and only want specific components.

```bash
# Test syntax first
make test-vm-syntax

# Run only core components (skip projects, aws, etc.)
ansible-playbook playbooks/after_format.yaml \
  --tags core \
  --ask-vault-pass \
  --ask-become-pass

# Or add specific tools
ansible-playbook playbooks/after_format.yaml \
  --tags core,python,go \
  --ask-vault-pass \
  --ask-become-pass

# Skip certain components
ansible-playbook playbooks/after_format.yaml \
  --skip-tags repos,aws,ngrok \
  --ask-vault-pass \
  --ask-become-pass
```

---

## Scenario 3: Testing Changes to a Role

You modified the `ssh` role and want to test it before deploying.

```bash
# 1. Test the role in isolation with Molecule
cd playbooks/roles/ssh
molecule test

# 2. Test in VM context with just that role
cd /home/fer/ansible
EXTRA_ARGS="--tags ssh" make test-vm-keep

# 3. Shell into VM to verify
multipass shell ansible-test

# Inside VM: check SSH setup
ls -la ~/.ssh/
cat ~/.ssh/config
ssh -T git@github.com

# Exit and clean up
exit
multipass delete ansible-test && multipass purge

# 4. Deploy locally if satisfied
ansible-playbook playbooks/after_format.yaml --tags ssh --ask-become-pass
```

---

## Scenario 4: Remote Server Setup (SSH Access)

You have a remote Ubuntu server and want to enable SSH access for VSCode/Cursor.

```bash
# 1. Test in local VM first
PLAYBOOK=playbooks/remote_ssh_server.yaml make test-vm-keep

# 2. If good, run on remote server
ansible-playbook -i "remote-server," playbooks/remote_ssh_server.yaml \
  --user ubuntu \
  --ask-become-pass

# With ngrok tunnel
ansible-playbook -i "remote-server," playbooks/remote_ssh_server.yaml \
  -e "enable_ngrok=true ngrok_authtoken=YOUR_TOKEN" \
  --ask-vault-pass \
  --ask-become-pass
```

---

## Scenario 5: Debugging a Failed Playbook

Your playbook failed and you want to understand why.

```bash
# 1. Run in VM with verbose output and keep the VM
VM_NAME=debug-vm \
  KEEP_VM=true \
  EXTRA_ARGS="-vv" \
  scripts/test_vm.sh

# 2. The playbook fails. Shell into the VM
multipass shell debug-vm

# 3. Investigate inside the VM
cd /home/ubuntu/ansible

# Check what failed
ansible-playbook playbooks/after_format.yaml --list-tasks
ansible-playbook playbooks/after_format.yaml --tags ssh -vvv

# Inspect files
cat ~/.ssh/config
ls -la /personal/
systemctl status ssh

# 4. Fix the issue in your local repo, then re-test
exit  # exit VM

# Transfer updated files
multipass transfer playbooks/roles/ssh/tasks/main.yml debug-vm:/home/ubuntu/ansible/playbooks/roles/ssh/tasks/main.yml

# Re-run in VM
multipass exec debug-vm -- bash -c "cd /home/ubuntu/ansible && ansible-playbook playbooks/after_format.yaml --tags ssh"

# 5. Clean up when done
multipass delete debug-vm && multipass purge
```

---

## Scenario 6: Custom VM Configuration for Testing

You need more resources for testing Python/R installations.

```bash
# Allocate more resources
make test-vm \
  vm_cpus=4 \
  vm_mem=8G \
  vm_disk=40G \
  EXTRA_ARGS="--tags core,python,R"

# Test on older Ubuntu version
make test-vm \
  ubuntu_major=22 \
  ubuntu_minor=04

# Test with different playbook
PLAYBOOK=playbooks/just_cuda.yaml \
  VM_NAME=cuda-test \
  VM_MEM=8G \
  scripts/test_vm.sh
```

---

## Scenario 7: Using Vault-Encrypted Files

You have vault-encrypted SSH keys and AWS credentials and want to test with them.

```bash
# 1. Ensure your vault password file exists
echo "my-vault-password" > ~/.vault_pass.txt
chmod 600 ~/.vault_pass.txt

# 2. Test that vault decryption works locally
ansible-vault view playbooks/roles/ssh/files/id_rsa --vault-password-file ~/.vault_pass.txt

# 3. Test in VM with vault password (recommended)
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm-core

# 4. Test full playbook including AWS and ngrok (also encrypted)
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm

# 5. If VM tests pass, run locally
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make run_local
```

**Alternative**: Use make variable instead of environment variable
```bash
make test-vm-core vault_pass_file=~/.vault_pass.txt
make run_local vault_pass_file=~/.vault_pass.txt
```

---

## Scenario 8: Working Without Secrets

You want to test but don't have vault-encrypted SSH keys yet.

```bash
# Skip roles that need secrets
EXTRA_ARGS="--skip-tags ssh,repos,aws,ngrok" make test-vm

# Or generate a temporary SSH key for testing
ssh-keygen -t rsa -b 4096 -f /tmp/test_id_rsa -N ""
cp /tmp/test_id_rsa playbooks/roles/ssh/files/id_rsa
cp /tmp/test_id_rsa.pub playbooks/roles/ssh/files/id_rsa.pub

# Now test
make test-vm-core

# Clean up after
rm playbooks/roles/ssh/files/id_rsa*
rm /tmp/test_id_rsa*
```

---

## Scenario 8: Iterative Development

You're developing a new role and need fast iteration.

```bash
# 1. Create the role
ansible-galaxy init playbooks/roles/mynewrole

# 2. Write tasks in playbooks/roles/mynewrole/tasks/main.yml

# 3. Test with Molecule (fastest)
cd playbooks/roles/mynewrole
molecule init scenario
molecule test

# 4. Test in VM context (add to after_format.yaml first)
cd /home/fer/ansible
EXTRA_ARGS="--tags mynewrole" make test-vm-keep

# 5. Iterate: edit locally, transfer, re-run
# Edit role files...
multipass transfer playbooks/roles/mynewrole/. ansible-test:/home/ubuntu/ansible/playbooks/roles/mynewrole/
multipass exec ansible-test -- bash -c "cd /home/ubuntu/ansible && ansible-playbook playbooks/after_format.yaml --tags mynewrole"

# 6. When satisfied, clean up
multipass delete ansible-test && multipass purge
```

---

## Scenario 9: Dry-Run (Check Mode)

You want to see what would change without actually changing anything.

```bash
# Local dry-run
ansible-playbook playbooks/after_format.yaml \
  --check \
  --diff \
  --tags core

# VM dry-run (more realistic)
EXTRA_ARGS="--check --diff" make test-vm-keep
```

---

## Scenario 10: Production-Like Full Test

Before running on your main machine, you want maximum confidence.

```bash
# 1. Syntax check
make test-vm-syntax

# 2. Test all roles individually
make test

# 3. Test core in VM
make test-vm-core

# 4. Test full playbook in VM
make test-vm

# 5. Test with your actual vault credentials
make test-vm vault_pass_file=.vault_password

# 6. All green? Run locally
make run_local vault_pass_file=.vault_password
```

---

## Common Patterns

### Skip Problematic Roles
```bash
EXTRA_ARGS="--skip-tags repos,aws,ngrok" make test-vm
```

### Run Specific Tags Only
```bash
EXTRA_ARGS="--tags ssh,vscode,python" make test-vm
```

### Verbose Output for Debugging
```bash
EXTRA_ARGS="-vvv" make test-vm-keep
```

### Different Ubuntu Versions
```bash
make test-vm ubuntu_major=22 ubuntu_minor=04
make test-vm ubuntu_major=20 ubuntu_minor=04
```

### Custom VM Names (Multiple VMs)
```bash
# Start multiple test VMs
VM_NAME=core-test EXTRA_ARGS="--tags core" make test-vm-keep &
VM_NAME=python-test EXTRA_ARGS="--tags python" make test-vm-keep &

# Clean up all
multipass delete core-test python-test && multipass purge
```

---

## Pro Tips

1. **Always start with syntax check**: `make test-vm-syntax` is instant and catches most errors
2. **Use `test-vm-core` during development**: Much faster than full runs
3. **Keep VMs for debugging**: `make test-vm-keep` lets you inspect the state
4. **Tag everything**: Use tags in your roles so you can test incrementally
5. **Commit frequently**: VM tests destroy and recreate, so uncommitted changes need to be transferred manually
6. **Use dry-run for safety**: `EXTRA_ARGS="--check"` shows what would happen
7. **Test incrementally**: Don't test everything at once - build up confidence role by role

---

## Getting Help

```bash
# Show all make targets
make help  # (if implemented) or just: make

# Show all playbook tasks
ansible-playbook playbooks/after_format.yaml --list-tasks

# Show all tags
ansible-playbook playbooks/after_format.yaml --list-tags

# Ansible help
ansible-playbook --help

# Multipass help
multipass help
multipass list
multipass info ansible-test
```

