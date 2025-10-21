# Snowflake Setup Solution

## Issue
GitHub Issue #19: Missing Snowflake role setup for environment variables and RSA key configuration.

## Problem Description
The Snowflake role was missing, causing authentication issues with Snowflake. The system needed:
1. Environment variables (SNOWFLAKE_*) to be loaded into the runtime environment
2. RSA private key (`~/.dbt/rsa_key.p8`) to be properly configured
3. DBT profiles (`~/.dbt/profiles.yml`) to be set up
4. All sensitive files to be encrypted with Ansible Vault

## Solution Implemented

### 1. Created Complete Snowflake Role Structure

Created the following directory structure:

```
playbooks/roles/snowflake/
├── defaults/
│   └── main.yml                    # Default variables
├── files/
│   ├── .env                        # Encrypted environment variables
│   └── .dbt/
│       ├── rsa_key.p8             # Encrypted RSA private key
│       ├── profiles.yml           # Encrypted DBT profiles
│       └── .user.yml              # Encrypted user configuration
├── meta/
│   └── main.yml                    # Role metadata
├── molecule/
│   └── default/
│       ├── converge.yml           # Test convergence
│       ├── molecule.yml           # Molecule configuration
│       └── verify.yml             # Test verification
├── tasks/
│   └── main.yml                    # Main task file
├── README.md                       # Role documentation
└── QUICK_START.md                  # Quick start guide
```

### 2. Key Features of the Role

#### tasks/main.yml
- Creates `~/.dbt` directory with proper permissions (0700)
- Copies encrypted `.env` file to home directory with decrypt enabled
- Copies encrypted RSA key to `~/.dbt/rsa_key.p8` with 0600 permissions
- Copies encrypted DBT profiles to `~/.dbt/profiles.yml`
- Configures shell RC files (`.zshrc` and `.bashrc`) to automatically source `.env`
- Verifies the setup with assertions
- Displays success message with file locations

#### Shell Configuration
The role adds the following block to shell configuration files:

```bash
# Load Snowflake environment variables from .env if it exists
if [ -f "$HOME/.env" ]; then
  set -a
  source "$HOME/.env"
  set +a
fi
```

This ensures that:
- Environment variables are loaded on every new shell session
- The `set -a` command exports all variables defined in `.env`
- The configuration is safe (checks file existence first)

### 3. Security Implementation

All sensitive files are encrypted with Ansible Vault:
- `.env` - Contains all SNOWFLAKE_* environment variables
- `rsa_key.p8` - RSA private key for authentication
- `profiles.yml` - DBT profiles configuration
- `.user.yml` - User-specific configuration

File permissions:
- `.dbt` directory: 0700 (owner read/write/execute only)
- All credential files: 0600 (owner read/write only)

### 4. Integration with Main Playbook

Added the Snowflake role to `playbooks/after_format.yaml`:

```yaml
- role: snowflake
  become: true
  become_user: aleph
  tags: ['snowflake']
```

Created standalone playbook `playbooks/snowflake_setup.yaml` for independent execution.

### 5. Testing Infrastructure

Implemented Molecule tests that verify:
- `.dbt` directory creation
- RSA key exists with correct permissions (0600)
- `profiles.yml` exists
- `.env` file exists with correct permissions (0600)

## Usage

### Running the Snowflake Role Alone

```bash
ansible-playbook playbooks/snowflake_setup.yaml --vault-password-file /path/to/vault/password
```

### Running as Part of Main Setup

```bash
ansible-playbook playbooks/after_format.yaml --tags snowflake --vault-password-file /path/to/vault/password
```

### Running the Full Setup (Including Snowflake)

```bash
ansible-playbook playbooks/after_format.yaml --vault-password-file /path/to/vault/password
```

## Verification

After running the playbook, verify the setup:

1. Check files exist:
   ```bash
   ls -la ~/.dbt/
   ls -la ~/.env
   ```

2. Verify permissions:
   ```bash
   stat -c "%a" ~/.dbt/rsa_key.p8  # Should show 600
   stat -c "%a" ~/.env              # Should show 600
   ```

3. Test environment variables (start new shell):
   ```bash
   exec $SHELL
   echo $SNOWFLAKE_ACCOUNT
   ```

## Files Modified/Created

### New Files Created:
- `playbooks/roles/snowflake/tasks/main.yml`
- `playbooks/roles/snowflake/defaults/main.yml`
- `playbooks/roles/snowflake/meta/main.yml`
- `playbooks/roles/snowflake/README.md`
- `playbooks/roles/snowflake/QUICK_START.md`
- `playbooks/roles/snowflake/molecule/default/molecule.yml`
- `playbooks/roles/snowflake/molecule/default/converge.yml`
- `playbooks/roles/snowflake/molecule/default/verify.yml`
- `playbooks/snowflake_setup.yaml`

### Files Modified:
- `playbooks/after_format.yaml` - Added snowflake role

### Files Already Present (User Provided):
- `playbooks/roles/snowflake/files/.env` (encrypted)
- `playbooks/roles/snowflake/files/.dbt/rsa_key.p8` (encrypted)
- `playbooks/roles/snowflake/files/.dbt/profiles.yml` (encrypted)
- `playbooks/roles/snowflake/files/.dbt/.user.yml` (encrypted)

## Environment Variables Expected

The `.env` file should contain:
- `SNOWFLAKE_ACCOUNT` - Your Snowflake account identifier
- `SNOWFLAKE_USER` - Your Snowflake username
- `SNOWFLAKE_ROLE` - Your Snowflake role
- `SNOWFLAKE_WAREHOUSE` - Your Snowflake warehouse
- `SNOWFLAKE_DATABASE` - Your Snowflake database
- `SNOWFLAKE_SCHEMA` - Your Snowflake schema

Additional Snowflake-specific variables can be added as needed.

## Next Steps

1. Run the playbook to set up Snowflake credentials
2. Test the Snowflake connection
3. Use DBT with the configured profiles
4. Consider running Molecule tests to verify the setup

## Troubleshooting

See `QUICK_START.md` in the snowflake role directory for detailed troubleshooting steps.

## Issue Resolution

This solution addresses GitHub Issue #19 by:
✅ Creating a complete Snowflake role with all necessary components
✅ Properly handling encrypted credentials with Ansible Vault
✅ Setting up environment variables that load automatically
✅ Configuring RSA key with correct permissions
✅ Setting up DBT profiles
✅ Adding comprehensive testing infrastructure
✅ Providing detailed documentation
✅ Integrating with the main playbook

The role follows Ansible best practices and maintains consistency with other roles in the project.

