# Testing Snowflake Role with Molecule and Ansible Vault

This guide explains how to test the Snowflake role using Molecule when your files are encrypted with Ansible Vault.

## Prerequisites

- Docker installed and running (for Molecule testing)
- Molecule and molecule-docker installed
- Ansible Vault password file or password ready

## Installation (if needed)

```bash
# Install Molecule with Docker driver
pip install molecule molecule-docker

# Or use the project's install script
bash scripts/install_molecule.sh
```

## Methods to Pass Vault Password

### Method 1: Environment Variable (Recommended)

Set the `ANSIBLE_VAULT_PASSWORD_FILE` environment variable:

```bash
# Export the environment variable
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass

# Then run molecule commands normally
cd playbooks/roles/snowflake
molecule test
```

Or in one line:

```bash
cd playbooks/roles/snowflake
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass molecule test
```

### Method 2: Configure in molecule.yml

Uncomment the vault_password_file line in `molecule/default/molecule.yml`:

```yaml
provisioner:
  name: ansible
  config_options:
    defaults:
      vault_password_file: ~/.vault_pass  # Uncomment and set path
```

Then run normally:

```bash
cd playbooks/roles/snowflake
molecule test
```

### Method 3: Use Molecule Environment Variables

Create a `.env` file in your role directory or set it in your shell:

```bash
# In your shell or .env file
export MOLECULE_VAULT_PASSWORD_FILE=~/.vault_pass
```

### Method 4: Use ansible.cfg

Add to your `ansible.cfg` (in the role directory or project root):

```ini
[defaults]
vault_password_file = ~/.vault_pass
```

### Method 5: Interactive Password Prompt

If you don't want to store the password in a file, you can use `--ask-vault-pass`:

Unfortunately, Molecule doesn't directly support `--ask-vault-pass`, so you'll need to use one of the file-based methods above.

## Common Molecule Commands with Vault

### Full Test Suite

```bash
# With environment variable
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass molecule test

# Or with exported variable
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass
molecule test
```

### Individual Test Steps

```bash
# Set the vault password file
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass

# Create test environment
molecule create

# Run the converge (apply the role)
molecule converge

# Run verification tests
molecule verify

# Login to the test container
molecule login

# Destroy test environment
molecule destroy
```

### Debug Mode

```bash
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass molecule --debug test
```

### Test with Specific Scenario

```bash
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass molecule test -s default
```

## Vault Password File Setup

If you don't have a vault password file yet:

1. **Create the password file:**

```bash
# Create file with your vault password
echo "your_vault_password_here" > ~/.vault_pass

# Secure the file
chmod 600 ~/.vault_pass
```

2. **Verify it works:**

```bash
# Test decryption
ansible-vault view --vault-password-file ~/.vault_pass playbooks/roles/snowflake/files/.env
```

## Testing Workflow

Here's a complete testing workflow:

```bash
# 1. Navigate to the role directory
cd /home/aleph/personal/ansible/playbooks/roles/snowflake

# 2. Set vault password file
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass

# 3. Run full test suite
molecule test

# Or run step by step for debugging:

# Create the test container
molecule create

# Apply the role
molecule converge

# Run verification tests
molecule verify

# Login to inspect (optional)
molecule login

# Clean up
molecule destroy
```

## Troubleshooting

### Error: "Attempting to decrypt but no vault secrets found"

**Solution:** Make sure your vault password file is correctly set:

```bash
# Verify the file exists
ls -la ~/.vault_pass

# Verify it contains the correct password
ansible-vault view --vault-password-file ~/.vault_pass playbooks/roles/snowflake/files/.env
```

### Error: "ERROR! Decryption failed"

**Solution:** Your vault password is incorrect. Double-check:

```bash
# Test manually
ansible-vault decrypt --vault-password-file ~/.vault_pass playbooks/roles/snowflake/files/.env --output=-
```

### Error: "docker.errors.DockerException: Error while fetching server API version"

**Solution:** Make sure Docker is running:

```bash
# Check Docker status
sudo systemctl status docker

# Start Docker if needed
sudo systemctl start docker
```

### Files not being decrypted in container

**Solution:** Ensure the vault password is being passed through. Check your molecule.yml configuration and environment variables.

## Inspecting Test Results

### Login to test container

```bash
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass
molecule create
molecule converge
molecule login
```

Inside the container, verify:

```bash
# Check if files were created
ls -la ~/.dbt/
ls -la ~/.env

# Check permissions
stat -c "%a" ~/.dbt/rsa_key.p8  # Should be 600
stat -c "%a" ~/.env              # Should be 600

# Try to read the decrypted content
cat ~/.env
cat ~/.dbt/profiles.yml
```

## CI/CD Integration

For GitHub Actions or other CI/CD:

```yaml
# .github/workflows/test.yml
- name: Test with Molecule
  env:
    ANSIBLE_VAULT_PASSWORD_FILE: ${{ secrets.VAULT_PASSWORD_FILE }}
  run: |
    echo "${{ secrets.VAULT_PASSWORD }}" > /tmp/vault_pass
    export ANSIBLE_VAULT_PASSWORD_FILE=/tmp/vault_pass
    molecule test
```

## Best Practices

1. **Never commit vault password files** - Add to `.gitignore`:
   ```
   .vault_pass
   vault_pass
   *_vault_pass
   ```

2. **Use environment variables** in automated environments

3. **Keep test files encrypted** - Don't create unencrypted test fixtures

4. **Test in isolation** - Each molecule test should be independent

5. **Clean up** - Always run `molecule destroy` after testing to clean up containers

## Quick Reference

```bash
# One-liner for complete test
cd /home/aleph/personal/ansible/playbooks/roles/snowflake && \
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass molecule test

# One-liner for quick convergence test
cd /home/aleph/personal/ansible/playbooks/roles/snowflake && \
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass molecule converge

# One-liner with destroy at the end
cd /home/aleph/personal/ansible/playbooks/roles/snowflake && \
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass molecule test && molecule destroy
```

## Additional Resources

- [Molecule Documentation](https://molecule.readthedocs.io/)
- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [Testing Ansible Roles with Molecule](https://www.jeffgeerling.com/blog/2018/testing-your-ansible-roles-molecule)

