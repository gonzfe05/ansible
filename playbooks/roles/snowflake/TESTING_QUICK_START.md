# Quick Start: Testing Snowflake Role with Molecule

## TL;DR

```bash
# Set your vault password file
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass

# Navigate to role directory
cd /home/aleph/personal/ansible/playbooks/roles/snowflake

# Run full test
molecule test
```

## Step-by-Step Testing

### 1. Setup Vault Password (One-time)

```bash
# If you don't have a vault password file yet:
echo "your_vault_password" > ~/.vault_pass
chmod 600 ~/.vault_pass
```

### 2. Set Environment Variables

```bash
# Export the vault password file location
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass

# Export the roles path (optional - has a default)
export ANSIBLE_ROLES_PATH=/home/aleph/personal/ansible/playbooks/roles
```

Add to your `~/.zshrc` or `~/.bashrc` to make it permanent:

```bash
echo 'export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass' >> ~/.zshrc
echo 'export ANSIBLE_ROLES_PATH=/home/aleph/personal/ansible/playbooks/roles' >> ~/.zshrc
source ~/.zshrc
```

### 3. Run Molecule Tests

```bash
# Navigate to the role
cd /home/aleph/personal/ansible/playbooks/roles/snowflake

# Run complete test suite
molecule test
```

## Alternative: One-Line Command

If you don't want to export the variable:

```bash
cd /home/aleph/personal/ansible/playbooks/roles/snowflake && \
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass molecule test
```

## Individual Test Steps (for debugging)

```bash
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass
cd /home/aleph/personal/ansible/playbooks/roles/snowflake

# Create test container
molecule create

# Apply the role
molecule converge

# Run verification tests
molecule verify

# Login to inspect (optional)
molecule login

# Inside container, check:
#   ls -la ~/.dbt/
#   ls -la ~/.env
#   cat ~/.env

# Destroy test container
molecule destroy
```

## Common Commands

```bash
# Full test (create, converge, verify, destroy)
molecule test

# Just run the role
molecule converge

# Just verify
molecule verify

# Login to test container
molecule login

# Destroy test environment
molecule destroy

# Debug mode
molecule --debug converge
```

## Verify Your Setup

Before running molecule, verify vault password works:

```bash
# Test decryption
ansible-vault view --vault-password-file ~/.vault_pass \
  playbooks/roles/snowflake/files/.env
```

You should see your decrypted environment variables.

## Troubleshooting

### Error: "the role 'snowflake' was not found"
- **Solution:** The `molecule.yml` now includes `roles-path: ../../../` to fix this
- If you still see this, verify you're in the role directory: `cd playbooks/roles/snowflake`

### Error: "no vault secrets found"
- **Solution:** `export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass`

### Error: "Decryption failed"
- **Solution:** Check your vault password in `~/.vault_pass`

### Error: "Docker error"
- **Solution:** Start Docker: `sudo systemctl start docker`

## Configuration

The role's `molecule/default/molecule.yml` is already configured to use environment variables:

```yaml
provisioner:
  name: ansible
  env:
    ANSIBLE_VAULT_PASSWORD_FILE: ${ANSIBLE_VAULT_PASSWORD_FILE}
    ANSIBLE_ROLES_PATH: ${ANSIBLE_ROLES_PATH:-/home/aleph/personal/ansible/playbooks/roles}
```

The `ANSIBLE_ROLES_PATH` uses a default value, so you don't need to set it unless your project is in a different location.

## See Also

- `MOLECULE_TESTING.md` - Comprehensive testing guide
- `QUICK_START.md` - Role usage guide
- `README.md` - Full role documentation

