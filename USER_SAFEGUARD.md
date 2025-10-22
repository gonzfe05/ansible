# User Safeguard - Preventing 'aleph' User Execution

## Overview

This repository includes a safeguard to prevent the `aleph` user from running the Ansible playbooks via the Makefile.

## Why This Safeguard?

The `aleph` user is **created and managed by this Ansible repository** (via the `users` role). Running this repository as `aleph` could cause:
- Circular dependency issues
- Permission conflicts
- Unintended configuration overwrites
- System instability

## Implementation

The safeguard is implemented at the **Makefile level** (lines 4-10):

```makefile
# Check that we're not running as the 'aleph' user (created by this repo)
CURRENT_USER := $(shell whoami)
ifeq ($(CURRENT_USER),aleph)
$(error ❌ ERROR: The 'aleph' user cannot run this Ansible repository.\
\nThe 'aleph' user is created and managed by this repository (via the 'users' role).\
\nRunning as 'aleph' could cause conflicts or permission issues.\
\nPlease run as your actual system user (e.g., 'fer') instead.)
endif
```

## What Happens

If the `aleph` user tries to run any make target, they will receive:

```
makefile:6: *** ❌ ERROR: The 'aleph' user cannot run this Ansible repository.
The 'aleph' user is created and managed by this repository (via the 'users' role).
Running as 'aleph' could cause conflicts or permission issues.
Please run as your actual system user (e.g., 'fer') instead.  Stop.
```

## Affected Commands

All make targets are protected:
- `make run_local`
- `make test`
- `make test-vm`
- `make test-vm-keep`
- `make test-vm-core`
- `make test-vm-syntax`
- Any custom targets

## Correct Usage

Run the repository as your actual system user:

```bash
# ✅ Correct - run as your actual user (e.g., fer)
make run_local vault_pass_file=~/.vault_pass

# ❌ Incorrect - will fail with error
su - aleph
make run_local  # ERROR!
```

## Direct ansible-playbook Execution

**Note**: This safeguard only applies to `make` commands. If someone runs `ansible-playbook` directly, they bypass this check:

```bash
# This will NOT be blocked by the makefile safeguard
ansible-playbook playbooks/after_format.yaml
```

If you need to block direct ansible-playbook execution as well, you would need to add checks within the playbook itself or individual role tasks.

## Testing the Safeguard

To verify the safeguard works:

```bash
# Test 1: Should work (assuming you're not 'aleph')
make test-vm-syntax

# Test 2: Simulate running as aleph (will fail)
sudo -u aleph make test-vm-syntax
# Expected: Error message about aleph user

# Test 3: Switch to aleph user (will fail)
su - aleph
cd /home/fer/ansible
make test-vm-syntax
# Expected: Error message about aleph user
```

## Bypassing (If Really Needed)

If you absolutely need to bypass this check (e.g., for testing), you can:

1. **Edit the makefile** temporarily:
   ```bash
   # Comment out lines 4-10
   ```

2. **Run ansible-playbook directly** (bypasses makefile):
   ```bash
   ansible-playbook playbooks/after_format.yaml
   ```

⚠️ **Warning**: Bypassing this safeguard is not recommended and may cause issues.

## Alternative Implementations Considered

### Option 1: Role-level Check (Not Used)
Could add a check in each role's `tasks/main.yml`:
```yaml
- name: Prevent aleph user
  fail:
    msg: "Cannot run as aleph user"
  when: ansible_user_id == "aleph"
```

**Pros**: Protects against direct ansible-playbook execution  
**Cons**: Requires changes in multiple files, harder to maintain

### Option 2: Playbook-level Check (Not Used)
Add a pre_tasks check in each playbook:
```yaml
- hosts: localhost
  pre_tasks:
    - name: Check user
      fail:
        msg: "Cannot run as aleph"
      when: ansible_user_id == "aleph"
```

**Pros**: Protects entire playbook  
**Cons**: Need to add to each playbook, doesn't protect make targets

### Option 3: Makefile Check (✅ Used)
Check at the makefile level (current implementation)

**Pros**: 
- Single point of control
- Protects all make targets
- Easy to maintain
- Clear error message

**Cons**: 
- Doesn't protect direct ansible-playbook execution
- Only works when using make

## Rationale for Makefile Implementation

The makefile approach was chosen because:

1. **Most common use case**: Users typically interact via `make` commands
2. **Single point of control**: One check protects all targets
3. **Early failure**: Error occurs before any expensive operations
4. **Clear intent**: Makefile is the "entry point" for this repo
5. **Easy to maintain**: One location to update if needed

## Future Enhancements

Potential improvements:
- Add a list of disallowed users (not just 'aleph')
- Add similar checks in playbooks for defense-in-depth
- Create a pre-commit hook to prevent accidental commits as aleph
- Add documentation about which user should run the repo

## Related Files

- `/home/fer/ansible/makefile` - Contains the safeguard
- `/home/fer/ansible/playbooks/roles/users/` - Creates the aleph user
- `/home/fer/ansible/playbooks/after_format.yaml` - Main playbook

## Author

Fernando Gonzalez - October 22, 2025

