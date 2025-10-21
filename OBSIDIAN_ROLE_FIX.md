# Obsidian Role Fix - Root Privilege Escalation

## Issue Found by VM Testing

The VM test discovered that the `obsidian` role failed with permission denied errors when trying to install apt packages because it wasn't properly escalating to root privileges.

## Root Cause

**Original issue:**
```yaml
# playbooks/after_format.yaml (line 79-82)
- role: obsidian
  become: true
  become_user: aleph  ← Role runs as aleph

# playbooks/roles/obsidian/tasks/main.yml (line 20-21, 35-36, 48-49)
- name: Install Obsidian runtime dependencies
  apt:
    name: [...]
  become: yes  ← Only says "escalate" but doesn't specify to root!
```

**The Problem:**
When a playbook runs a role as a non-root user (aleph), saying `become: yes` in a task doesn't automatically escalate to root. It just means "use privilege escalation" but stays as the current user if no `become_user` is specified.

**Error message:**
```
Failed to lock apt for exclusive operation:
Could not open lock file /var/lib/apt/lists/lock - open (13: Permission denied)
```

## Why Molecule Didn't Catch It

**Molecule test setup:**
```yaml
# playbooks/roles/obsidian/molecule/default/converge.yml
- name: Converge
  hosts: instance
  become: yes
  become_user: root  ← Already running as root!
```

When Molecule runs:
- Play level: `become_user: root` 
- Task level: `become: yes`
- Result: Stays as root → Has apt permissions ✅

When VM test runs:
- Play level: `become_user: aleph` (from playbook)
- Task level: `become: yes`
- Result: Stays as aleph → No apt permissions ❌

## Solution Applied

Added explicit `become_user: root` to all apt-related tasks in the Obsidian role.

### Changes Made

**File:** `playbooks/roles/obsidian/tasks/main.yml`

#### 1. Ubuntu 22.04 dependencies (lines 20-21)
```yaml
- name: Install Obsidian runtime dependencies (Ubuntu 22.04 and earlier)
  apt:
    name: [...]
  become: yes
  become_user: root  # ← ADDED
  when: ansible_distribution_version is version('24.04', '<')
```

#### 2. Ubuntu 24.04 dependencies (lines 35-36)
```yaml
- name: Install Obsidian runtime dependencies (Ubuntu 24.04 and later)
  apt:
    name: [...]
  become: yes
  become_user: root  # ← ADDED
  when: ansible_distribution_version is version('24.04', '>=')
```

#### 3. Obsidian .deb installation (lines 48-49)
```yaml
- name: Install Obsidian from .deb
  ansible.builtin.apt:
    deb: /tmp/obsidian.deb
  become: yes
  become_user: root  # ← ADDED
  register: obsidian_deb_install
```

## Benefits of This Fix

✅ **Self-contained role**: Works correctly regardless of how playbook calls it  
✅ **Explicit privilege escalation**: Clear what runs as root  
✅ **Principle of least privilege**: Only apt tasks run as root, not entire role  
✅ **Consistent with other roles**: Follows same pattern as apt_installs, vscode, etc.  
✅ **Works for any user**: Aleph, fer, or any user can run the playbook  

## Installation vs Execution

### Installation (needs root)
- Installing packages modifies `/usr/`, `/opt/`, `/var/`, `/etc/`
- Requires root privileges
- Done by: `apt install` commands
- One-time setup

### Execution (any user)
- Running installed programs reads from `/usr/bin/obsidian`
- Requires only read & execute permissions
- Done by: Regular users typing `obsidian` in terminal
- Every time the app is launched

**After this fix:**
- Root installs Obsidian (via Ansible)
- Aleph (or any user) can run Obsidian

## Testing

### Syntax Check
```bash
ansible-playbook playbooks/after_format.yaml --syntax-check
```
✅ Passed

### Expected VM Test Result
```bash
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm
```
Expected: Should now pass the obsidian role without permission errors

### Molecule Test
```bash
cd playbooks/roles/obsidian
molecule test
```
Expected: Should still pass (already ran as root)

## Why This Fix is Better Than Changing the Playbook

### Option A: Fix the role (CHOSEN) ✅
```yaml
# In role tasks:
become_user: root  # Explicit where needed
```
**Advantages:**
- Role is self-contained and portable
- Works regardless of playbook configuration
- Follows single responsibility principle
- Only privileged operations run as root

### Option B: Fix the playbook ❌
```yaml
# In playbook:
- role: obsidian
  become_user: root  # Entire role as root
```
**Disadvantages:**
- Entire role runs as root (unnecessary)
- Other playbooks might have same issue
- Less flexible for future changes
- Violates principle of least privilege

## Lessons Learned

1. **VM testing catches integration issues**: Molecule tests in isolation, VM tests in real context
2. **become: yes is not enough**: Must specify `become_user: root` when not already root
3. **Privilege escalation context matters**: What works in one context may fail in another
4. **Explicit is better than implicit**: Always specify `become_user` for clarity

## Related Files

- `playbooks/roles/obsidian/tasks/main.yml` - Fixed with explicit root escalation
- `playbooks/roles/obsidian/molecule/default/converge.yml` - Molecule test (as root)
- `playbooks/after_format.yaml` - Main playbook (calls role as aleph)

## Ansible Become Directive Behavior

| Context | become | become_user | Result |
|---------|--------|-------------|--------|
| Play: root | yes | (not set) | Stays root |
| Play: aleph | yes | (not set) | Stays aleph ❌ |
| Play: aleph | yes | root | Escalates to root ✅ |
| Task only | yes | root | Escalates to root ✅ |

**Key takeaway:** Always specify `become_user: root` for tasks that need root privileges.

---

**Fixed:** October 21, 2025  
**Discovered by:** VM testing infrastructure  
**Impact:** High - Would have failed on real machines  
**Bug #:** 2 of 2 found by VM testing
