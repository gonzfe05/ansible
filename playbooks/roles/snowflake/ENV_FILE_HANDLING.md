# Snowflake Role - .env File Handling

## Overview

The Snowflake role uses `ansible.builtin.blockinfile` to manage Snowflake-related environment variables in the user's `~/.env` file. This approach **preserves existing environment variables** while managing Snowflake credentials.

## How It Works

### Blockinfile Approach

The role uses Ansible's `blockinfile` module to insert Snowflake credentials into the user's `.env` file:

```yaml
- name: Add Snowflake environment variables to .env file
  ansible.builtin.blockinfile:
    path: "{{ user_home.stdout }}/.env"
    block: "{{ snowflake_env_content }}"
    marker: "# {mark} ANSIBLE MANAGED BLOCK - SNOWFLAKE CREDENTIALS"
    create: yes
    mode: '0600'
```

### Key Benefits

1. **Preserves Existing Variables**: If the user has other environment variables in their `.env` file (e.g., `DATABASE_URL`, `API_KEY`), those are preserved.

2. **Idempotent**: Running the role multiple times will **not** duplicate the Snowflake variables. The managed block is replaced each time, not appended.

3. **Automatic Updates**: If you change a Snowflake variable in the role's encrypted `.env` file and re-run the playbook, the block is updated with the new values automatically.

4. **Creates File if Missing**: If the user doesn't have a `.env` file, it will be created with appropriate permissions (`0600`).

## Example Behavior

### Initial State
User's `~/.env` might contain:
```bash
DATABASE_URL=postgresql://localhost/mydb
API_KEY=abc123
```

### After Running Snowflake Role
The file becomes:
```bash
DATABASE_URL=postgresql://localhost/mydb
API_KEY=abc123
# BEGIN ANSIBLE MANAGED BLOCK - SNOWFLAKE CREDENTIALS
SNOWFLAKE_ACCOUNT=myaccount
SNOWFLAKE_USER=myuser
SNOWFLAKE_WAREHOUSE=mywarehouse
# ... other Snowflake variables ...
# END ANSIBLE MANAGED BLOCK - SNOWFLAKE CREDENTIALS
```

### After Running Again (Idempotent)
The file remains the same - no duplication occurs. The block between the markers is managed by Ansible.

### After Updating Snowflake Variables
If you change `SNOWFLAKE_WAREHOUSE=newwarehouse` in the role's encrypted `.env` and re-run:
```bash
DATABASE_URL=postgresql://localhost/mydb
API_KEY=abc123
# BEGIN ANSIBLE MANAGED BLOCK - SNOWFLAKE CREDENTIALS
SNOWFLAKE_ACCOUNT=myaccount
SNOWFLAKE_USER=myuser
SNOWFLAKE_WAREHOUSE=newwarehouse  # ← Updated!
# ... other Snowflake variables ...
# END ANSIBLE MANAGED BLOCK - SNOWFLAKE CREDENTIALS
```

## Important Notes

### Managed Block Only
- ⚠️ Ansible **only** manages the content between the marker comments
- Variables outside the markers are never touched by this role
- You can safely add/modify other variables outside the managed block

### File Permissions
- The `.env` file is created with mode `0600` (read/write for owner only)
- This ensures sensitive credentials are not readable by other users

### Security
- The role uses `no_log: true` to prevent sensitive data from appearing in Ansible logs
- The source `.env` file should be encrypted with `ansible-vault`

## Migration from Previous Version

If you were using an older version of this role that used `ansible.builtin.copy`, be aware that:

1. **Previous behavior**: The entire `.env` file was replaced, losing any non-Snowflake variables
2. **New behavior**: Only the Snowflake section is managed, preserving other variables

No manual migration is needed. When you run the updated role, it will automatically create the managed block approach.

## Troubleshooting

### Variables Not Loading
If environment variables aren't loading:
1. Check that `.zshrc` or `.bashrc` has the source block (added by the role)
2. Start a new shell session or run `source ~/.env`

### Duplicate Variables
If you see duplicate variables:
- Check if they exist both inside and outside the managed block
- Remove any Snowflake variables outside the managed block to avoid conflicts

### Permission Denied
If you get permission errors:
- Verify the `.env` file has mode `0600`
- Run: `chmod 600 ~/.env`

## Technical Details

### Marker Comments
The role uses these markers to identify its managed section:
```
# BEGIN ANSIBLE MANAGED BLOCK - SNOWFLAKE CREDENTIALS
# END ANSIBLE MANAGED BLOCK - SNOWFLAKE CREDENTIALS
```

⚠️ **Do not manually edit or remove these markers** - they are required for idempotency.

### Encrypted Source File
The role reads from `files/.env` which should be encrypted:
```bash
# Encrypt the file
ansible-vault encrypt playbooks/roles/snowflake/files/.env

# Edit encrypted file
ansible-vault edit playbooks/roles/snowflake/files/.env
```

When running the playbook, provide the vault password:
```bash
ansible-playbook playbook.yml --ask-vault-pass
```

