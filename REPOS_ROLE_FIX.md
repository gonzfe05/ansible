# Repos Role Fix - User Home Directories

## Issue Found by VM Testing

The VM test discovered that the `repos` role was trying to clone repositories into `/personal` and `/work` directories that didn't exist and couldn't be created by non-root users.

## Root Cause

**Original configuration:**
```yaml
# playbooks/roles/repos/vars/main.yml
personal_folder: /personal
work_folder: /work
```

**Problems:**
1. These directories don't exist on a fresh Ubuntu installation
2. Non-root users can't create directories in `/`
3. Molecule tests hid this by overriding to `/home/aleph/personal`

## Solution Applied

### 1. Changed Paths to User Home Directory

**File:** `playbooks/roles/repos/vars/main.yml`

```yaml
personal_folder: "{{ ansible_env.HOME }}/personal"
work_folder: "{{ ansible_env.HOME }}/work"
```

**Benefits:**
- ✅ Works for any user
- ✅ No root permissions needed
- ✅ Standard Linux practice
- ✅ Consistent with Molecule tests
- ✅ Follows pattern of other roles (.ssh, .aws, etc.)

### 2. Added Explicit Directory Creation

**File:** `playbooks/roles/repos/tasks/main.yml`

Added at the beginning:
```yaml
---
- name: Ensure personal folder exists
  ansible.builtin.file:
    path: "{{ personal_folder }}"
    state: directory
    mode: '0755'

- name: Ensure work folder exists
  ansible.builtin.file:
    path: "{{ work_folder }}"
    state: directory
    mode: '0755'
```

**Benefits:**
- ✅ Idempotent (safe to run multiple times)
- ✅ Creates directories if they don't exist
- ✅ Sets proper permissions
- ✅ Explicit and clear

## Path Resolution Examples

| User | HOME | personal_folder | work_folder |
|------|------|-----------------|-------------|
| aleph | /home/aleph | /home/aleph/personal | /home/aleph/work |
| fer | /home/fer | /home/fer/personal | /home/fer/work |
| ubuntu | /home/ubuntu | /home/ubuntu/personal | /home/ubuntu/work |

## Impact on Molecule Tests

The Molecule test already used `/home/aleph/personal` as an override, so this change makes the **actual role behavior match the Molecule test**, eliminating the inconsistency.

**Before:** Molecule tested one path, real playbook used another  
**After:** Both use the same pattern (home directory)

## Testing

### Syntax Check
```bash
ansible-playbook playbooks/after_format.yaml --syntax-check
```
✅ Passed

### VM Test
```bash
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm
```
Expected: Should now pass the repos role without permission errors

### Molecule Test
```bash
cd playbooks/roles/repos
molecule test
```
Expected: Should still pass (paths are compatible)

## Why This Fix is Better Than /personal

### Original Approach (/personal, /work)
❌ Requires root to create directories  
❌ Not standard Linux practice  
❌ Doesn't exist by default  
❌ Inconsistent with Molecule tests  
❌ Permission issues for non-root users  

### New Approach (~/personal, ~/work)
✅ No root permissions needed  
✅ Standard Linux practice  
✅ Works immediately  
✅ Consistent with Molecule tests  
✅ User has full control  
✅ Portable across users  

## Lessons Learned

1. **VM testing is essential**: Caught a real bug that Molecule missed
2. **Molecule can hide issues**: Overrides can mask real-world problems
3. **Integration testing matters**: Unit tests (Molecule) + Integration tests (VM) = comprehensive coverage
4. **User home is safer**: Avoid system paths when possible

## Related Files

- `playbooks/roles/repos/vars/main.yml` - Variable definitions
- `playbooks/roles/repos/tasks/main.yml` - Task definitions
- `playbooks/roles/repos/molecule/default/converge.yml` - Molecule test setup
- `playbooks/after_format.yaml` - Main playbook using the repos role

---

**Fixed:** October 21, 2025  
**Discovered by:** VM testing infrastructure  
**Impact:** High - Would have failed on real machines
