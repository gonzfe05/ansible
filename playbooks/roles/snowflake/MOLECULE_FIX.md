# Molecule Role Path Fix

## Issue
When running `molecule test` from the snowflake role directory, Molecule couldn't find the role:

```
[ERROR]: the role 'snowflake' was not found in /home/aleph/personal/ansible/playbooks/roles/snowflake/molecule/default/roles:/home/aleph/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles
```

## Root Cause
Molecule by default looks for roles in specific directories, but when running from within a role's directory structure, it doesn't automatically find the role in the parent directory.

## Solution

### 1. Fixed `molecule.yml` - Added ANSIBLE_ROLES_PATH

Added the `ANSIBLE_ROLES_PATH` environment variable to point to the roles directory:

```yaml
provisioner:
  name: ansible
  env:
    ANSIBLE_VAULT_PASSWORD_FILE: ${ANSIBLE_VAULT_PASSWORD_FILE}
    ANSIBLE_ROLES_PATH: ${ANSIBLE_ROLES_PATH:-/home/aleph/personal/ansible/playbooks/roles}
  inventory:
    host_vars:
      instance:
        ansible_python_interpreter: /usr/bin/python3
```

This approach:
- Uses the standard `ANSIBLE_ROLES_PATH` environment variable
- Provides a sensible default path if not set
- Works with absolute paths, avoiding relative path issues

### 2. Fixed `converge.yml` - Updated host and setup

Changed from `hosts: all` to `hosts: instance` (matching the platform name) and added necessary setup:

```yaml
---
- name: Converge
  hosts: instance
  become: true
  become_user: root
  tasks:
    - name: Create test user aleph if it doesn't exist
      ansible.builtin.user:
        name: aleph
        state: present
        create_home: yes
        shell: /bin/bash
    
    - name: Ensure zsh is installed
      ansible.builtin.apt:
        name: zsh
        state: present
        update_cache: yes
    
    - name: Create .zshrc for test user
      ansible.builtin.file:
        path: /home/aleph/.zshrc
        state: touch
        owner: aleph
        group: aleph
        mode: '0644'
    
    - name: Apply snowflake role
      include_role:
        name: snowflake
      become: true
      become_user: aleph
```

### 3. Fixed `verify.yml` - Updated host reference

Changed from `hosts: all` to `hosts: instance`:

```yaml
---
- name: Verify
  hosts: instance
  gather_facts: false
  become: true
  become_user: aleph
  tasks:
    # ... verification tasks
```

## Testing Now Works

After these fixes, you can now run:

```bash
# Set vault password
export ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass

# Run molecule test
cd /home/aleph/personal/ansible/playbooks/roles/snowflake
molecule test
```

## Why Environment Variable Instead of Relative Path?

Initially tried using `options.roles-path: ../../../` but this doesn't work because:
- `--roles-path` is not a valid ansible-playbook argument
- Relative paths can be fragile depending on where commands are run from

Using `ANSIBLE_ROLES_PATH` environment variable is the standard Ansible approach:
- It's a documented Ansible configuration variable
- Works consistently regardless of working directory
- Can be overridden easily if needed

## Verification

To verify the fix is working:

1. **Syntax check:**
   ```bash
   molecule syntax
   ```

2. **Just converge (faster):**
   ```bash
   molecule converge
   ```

3. **Full test:**
   ```bash
   molecule test
   ```

4. **Debug if needed:**
   ```bash
   molecule --debug converge
   ```

## Key Takeaways

1. **roles-path** in molecule.yml tells Ansible where to find roles
2. **Platform name** in platforms must match the hosts in playbooks
3. **Test setup** should create the necessary environment (users, files, etc.)
4. **Vault password** is passed via environment variable `ANSIBLE_VAULT_PASSWORD_FILE`

