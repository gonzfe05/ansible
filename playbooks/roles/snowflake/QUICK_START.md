# Snowflake Role Quick Start

This guide will help you quickly set up the Snowflake role with encrypted credentials.

## Prerequisites

1. Ansible installed on your system
2. Ansible Vault password file configured
3. Your Snowflake credentials ready (account, user, role, warehouse, database, schema)
4. RSA private key for Snowflake authentication

## Setup Steps

### 1. Prepare Your Files

Create the following files in `playbooks/roles/snowflake/files/`:

#### Create `.env` file:
```bash
cat > playbooks/roles/snowflake/files/.env << 'EOF'
export SNOWFLAKE_ACCOUNT=your_account
export SNOWFLAKE_USER=your_username
export SNOWFLAKE_ROLE=your_role
export SNOWFLAKE_WAREHOUSE=your_warehouse
export SNOWFLAKE_DATABASE=your_database
export SNOWFLAKE_SCHEMA=your_schema
EOF
```

#### Create `.dbt/` directory and files:
```bash
mkdir -p playbooks/roles/snowflake/files/.dbt
```

Place your RSA private key at:
```
playbooks/roles/snowflake/files/.dbt/rsa_key.p8
```

Create your DBT profiles at:
```
playbooks/roles/snowflake/files/.dbt/profiles.yml
```

### 2. Encrypt Sensitive Files

Encrypt all sensitive files with Ansible Vault:

```bash
# Encrypt the .env file
ansible-vault encrypt playbooks/roles/snowflake/files/.env

# Encrypt the RSA key
ansible-vault encrypt playbooks/roles/snowflake/files/.dbt/rsa_key.p8

# Encrypt the profiles.yml
ansible-vault encrypt playbooks/roles/snowflake/files/.dbt/profiles.yml

# Encrypt the .user.yml if you have one
ansible-vault encrypt playbooks/roles/snowflake/files/.dbt/.user.yml
```

### 3. Create a Playbook

Create a playbook to use the Snowflake role:

```yaml
# playbooks/snowflake_setup.yaml
---
- name: Setup Snowflake credentials
  hosts: localhost
  connection: local
  roles:
    - snowflake
```

### 4. Run the Playbook

Execute the playbook with your vault password file:

```bash
ansible-playbook playbooks/snowflake_setup.yaml --vault-password-file /path/to/vault/password
```

Or with the vault password file from ansible.cfg:

```bash
ansible-playbook playbooks/snowflake_setup.yaml
```

### 5. Verify the Setup

After running the playbook, verify that:

1. Files were copied correctly:
   ```bash
   ls -la ~/.dbt/
   ls -la ~/.env
   ```

2. Permissions are correct (should be 600):
   ```bash
   stat -c "%a" ~/.dbt/rsa_key.p8
   stat -c "%a" ~/.env
   ```

3. Environment variables will be loaded on next shell session:
   ```bash
   # Start a new shell session
   exec $SHELL
   
   # Check if variables are loaded
   echo $SNOWFLAKE_ACCOUNT
   ```

## Troubleshooting

### Environment Variables Not Loading

If environment variables are not being loaded:

1. Check that the block was added to your shell RC file:
   ```bash
   grep -A 5 "SNOWFLAKE ENV" ~/.zshrc
   # or
   grep -A 5 "SNOWFLAKE ENV" ~/.bashrc
   ```

2. Make sure to start a new shell session or source your RC file:
   ```bash
   source ~/.zshrc
   # or
   source ~/.bashrc
   ```

### Permission Errors

If you get permission errors:

1. Verify file permissions:
   ```bash
   ls -la ~/.dbt/rsa_key.p8
   ```

2. Fix permissions if needed:
   ```bash
   chmod 600 ~/.dbt/rsa_key.p8
   chmod 600 ~/.env
   ```

### Vault Decryption Errors

If you get vault decryption errors:

1. Verify your vault password is correct
2. Check that the vault password file path is correct in `ansible.cfg`
3. Try decrypting manually to test:
   ```bash
   ansible-vault view playbooks/roles/snowflake/files/.env
   ```

## Next Steps

- Test your Snowflake connection
- Use DBT with the configured profiles
- Add the role to your main playbook if needed

## Security Best Practices

1. **Never commit unencrypted credentials** to version control
2. **Keep your Ansible Vault password secure** and never commit it
3. **Use SSH agent forwarding** when running playbooks on remote machines
4. **Regularly rotate** your Snowflake credentials and RSA keys
5. **Use appropriate file permissions** (0600) for all sensitive files

