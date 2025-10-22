# Migration to Blockinfile for .env Management

## Date
October 22, 2025

## Summary

The Snowflake role has been updated to use `ansible.builtin.blockinfile` instead of `ansible.builtin.copy` for managing the `~/.env` file. This change ensures that existing environment variables are preserved while managing Snowflake credentials.

## Changes Made

### 1. Updated tasks/main.yml

**Before:**
```yaml
- name: Copy encrypted .env file
  ansible.builtin.copy:
    src: files/.env
    dest: "{{ user_home.stdout }}/.env"
    mode: '0600'
    decrypt: yes
```

**After:**
```yaml
- name: Read encrypted .env file content
  ansible.builtin.set_fact:
    snowflake_env_content: "{{ lookup('file', 'files/.env') }}"
  no_log: true

- name: Add Snowflake environment variables to .env file
  ansible.builtin.blockinfile:
    path: "{{ user_home.stdout }}/.env"
    block: "{{ snowflake_env_content }}"
    marker: "# {mark} ANSIBLE MANAGED BLOCK - SNOWFLAKE CREDENTIALS"
    create: yes
    mode: '0600'
  no_log: true
```

### 2. Updated Success Message

Changed the display message to reflect the new behavior:
```yaml
- Snowflake credentials added to {{ user_home.stdout }}/.env (preserves existing variables)
```

### 3. Documentation

Created comprehensive documentation:
- **ENV_FILE_HANDLING.md**: Detailed explanation of how the blockinfile approach works
- **Updated README.md**: Added notes about variable preservation and idempotency
- **This file (BLOCKINFILE_MIGRATION.md)**: Migration summary

## Benefits

### 1. Preservation of Existing Variables
- Users can have other environment variables in their `.env` file
- Only Snowflake-related variables are managed by this role
- No data loss when running the role

### 2. Idempotency
- Running the role multiple times doesn't duplicate variables
- The managed block is replaced, not appended
- Meets Ansible best practices

### 3. Automatic Updates
- When Snowflake variables are updated in the encrypted source file, they're automatically updated in the user's `.env`
- The blockinfile module handles the replacement of the managed section

### 4. Safety
- Uses `no_log: true` to prevent credential leakage in logs
- Maintains `0600` file permissions for security
- Creates file if it doesn't exist

## How It Works

1. **Read Phase**: The encrypted `.env` file from `files/.env` is read using the `lookup` function
2. **Store Phase**: Content is stored in a fact variable `snowflake_env_content`
3. **Write Phase**: The content is inserted into the user's `~/.env` between marker comments
4. **Markers**: Ansible uses special comments to identify its managed section:
   ```
   # BEGIN ANSIBLE MANAGED BLOCK - SNOWFLAKE CREDENTIALS
   [Snowflake variables here]
   # END ANSIBLE MANAGED BLOCK - SNOWFLAKE CREDENTIALS
   ```

## Example Scenario

### User's Initial .env
```bash
DATABASE_URL=postgresql://localhost/mydb
API_KEY=abc123
```

### After Running Snowflake Role
```bash
DATABASE_URL=postgresql://localhost/mydb
API_KEY=abc123
# BEGIN ANSIBLE MANAGED BLOCK - SNOWFLAKE CREDENTIALS
SNOWFLAKE_ACCOUNT=myaccount
SNOWFLAKE_USER=myuser
SNOWFLAKE_WAREHOUSE=mywarehouse
# END ANSIBLE MANAGED BLOCK - SNOWFLAKE CREDENTIALS
```

### After Running Again (Second Run)
```bash
DATABASE_URL=postgresql://localhost/mydb
API_KEY=abc123
# BEGIN ANSIBLE MANAGED BLOCK - SNOWFLAKE CREDENTIALS
SNOWFLAKE_ACCOUNT=myaccount
SNOWFLAKE_USER=myuser
SNOWFLAKE_WAREHOUSE=mywarehouse
# END ANSIBLE MANAGED BLOCK - SNOWFLAKE CREDENTIALS
```
**No duplication** - the block is replaced, not appended.

## Testing

To test the new behavior:

1. Create a `.env` file with some test variables:
   ```bash
   echo "TEST_VAR=original_value" > ~/.env
   ```

2. Run the Snowflake role:
   ```bash
   ansible-playbook playbooks/after_format.yaml --ask-vault-pass --tags snowflake
   ```

3. Verify the file contains both your original variable and the Snowflake section:
   ```bash
   cat ~/.env
   ```

4. Run the role again and verify no duplication occurs

5. Modify a Snowflake variable in `files/.env` and re-run to verify updates work

## Backwards Compatibility

This change is **backwards compatible** in the sense that:
- The role will work with existing playbooks without modification
- Users who upgrade will automatically get the new behavior
- However, note that the behavior itself has changed from "replace" to "preserve and manage"

If users were relying on the previous "replace everything" behavior, they should be aware of this change.

## Security Considerations

- The encrypted source file (`files/.env`) is read using `lookup('file', ...)` which respects vault encryption
- The `no_log: true` directive prevents sensitive data from appearing in Ansible output
- File permissions remain at `0600` for security
- The managed block markers are visible in the file but contain no sensitive information

## Potential Issues and Solutions

### Issue 1: Duplicate Variables
**Problem**: Variables exist both inside and outside the managed block  
**Solution**: Manually remove Snowflake variables from outside the managed block

### Issue 2: Markers Accidentally Deleted
**Problem**: User deletes the marker comments  
**Solution**: Blockinfile will recreate them on next run, but may create a new block

### Issue 3: Manual Edits to Managed Block
**Problem**: User manually edits variables inside the managed block  
**Solution**: Changes will be overwritten on next playbook run - this is intentional

## Related Files

- `/home/fer/ansible/playbooks/roles/snowflake/tasks/main.yml` - Main tasks file
- `/home/fer/ansible/playbooks/roles/snowflake/README.md` - Updated README
- `/home/fer/ansible/playbooks/roles/snowflake/ENV_FILE_HANDLING.md` - Detailed documentation
- `/home/fer/ansible/playbooks/roles/snowflake/files/.env` - Encrypted source file

## Questions Answered

**Q: Is the .env file being appended or replaced?**  
A: Neither exactly. It uses blockinfile which manages a specific section (block) of the file while preserving everything else.

**Q: What if I run the role twice?**  
A: The managed block is replaced with the same content - no duplication occurs (idempotent).

**Q: If I change a variable in the role's .env, will the new value be used?**  
A: Yes! Blockinfile replaces the entire managed block, so updated variables are applied.

**Q: What if the .env file doesn't exist?**  
A: The `create: yes` option ensures the file is created with proper permissions.

**Q: Can I have other variables in my .env?**  
A: Absolutely! That's the whole point of this change - to preserve non-Snowflake variables.

