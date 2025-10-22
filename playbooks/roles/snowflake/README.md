# Snowflake Role

This Ansible role sets up Snowflake credentials and DBT profiles on a target system.

## Description

The Snowflake role handles:
- Adding Snowflake environment variables to `~/.env` (preserves existing variables)
- Setting up the RSA private key for Snowflake authentication in `~/.dbt/rsa_key.p8`
- Configuring DBT profiles in `~/.dbt/profiles.yml`
- Automatically sourcing environment variables in shell configuration files

**Note**: This role uses `blockinfile` to manage Snowflake credentials in `~/.env`, which means:
- ✅ Existing environment variables in `~/.env` are preserved
- ✅ Running the role multiple times is idempotent (no duplication)
- ✅ Updating Snowflake variables automatically updates the managed block
- See [ENV_FILE_HANDLING.md](ENV_FILE_HANDLING.md) for detailed information

## Requirements

- Ansible 2.1 or higher
- Ansible Vault password file for decrypting credentials
- The following files must be encrypted with Ansible Vault and placed in `files/`:
  - `.env` - Snowflake environment variables
  - `.dbt/rsa_key.p8` - RSA private key
  - `.dbt/profiles.yml` - DBT profiles configuration
  - `.dbt/.user.yml` - User configuration (optional)

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

```yaml
snowflake_setup_enabled: true
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: localhost
  roles:
    - role: snowflake
```

## Environment Variables

The `.env` file should contain the following Snowflake environment variables:
- `SNOWFLAKE_ACCOUNT`
- `SNOWFLAKE_USER`
- `SNOWFLAKE_ROLE`
- `SNOWFLAKE_WAREHOUSE`
- `SNOWFLAKE_DATABASE`
- `SNOWFLAKE_SCHEMA`
- Any other Snowflake-specific variables needed for your setup

## Security

All sensitive files (`.env`, `rsa_key.p8`, `profiles.yml`) are encrypted using Ansible Vault. Make sure to:
1. Never commit unencrypted credentials to version control
2. Keep your Ansible Vault password secure
3. Use appropriate file permissions (0600) for sensitive files

## Files Structure

```
files/
  .env                    # Encrypted environment variables
  .dbt/
    rsa_key.p8           # Encrypted RSA private key
    profiles.yml         # Encrypted DBT profiles
    .user.yml            # Encrypted user configuration (optional)
```

## Testing

This role can be tested using Molecule:

```bash
cd playbooks/roles/snowflake
molecule test
```

## License

GPL-2.0-or-later

## Author Information

Fernando Gonzalez

