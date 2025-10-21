# Fix for Issue #3: X11 Authorization and Clipboard Access

**Issue**: [#3 - aleph user doesn't have permission for X server](https://github.com/gonzfe05/ansible/issues/3)

**Problem**: When switching to the `aleph` user (or any secondary user), GUI applications and clipboard operations fail with authorization errors.

**Symptoms**:
- `xclip` fails with: "Authorization required, but no authorization protocol specified" and "Can't open display"
- Vim clipboard operations (`"+y` or with `clipboard=unnamedplus`) don't work
- VSCode and other GUI apps won't launch
- Error: "Missing X server or $DISPLAY"

## Root Cause

When you switch users with `sudo su aleph` or similar, the new user session doesn't have permission to access the X server of the original graphical session. The X server uses authentication to prevent unauthorized access to the display.

## Solution Implemented

This repository now includes a comprehensive fix with three components:

### 1. X11 Authorization Role (`playbooks/roles/x11_auth`)

A new Ansible role that:
- Grants X server access to specified users using `xhost +si:localuser:<username>`
- Creates persistent configuration via `/etc/profile.d/x11-auth-secondary-users.sh`
- Sets up a systemd user service as an alternative startup method
- Runs immediately during playbook execution

**Location**: `playbooks/roles/x11_auth/`

### 2. Vim Clipboard Configuration (`env_setup` role)

Automatic configuration of Vim/Neovim clipboard integration:
- Adds `set clipboard=unnamedplus` to `~/.vimrc`
- Configures Ctrl+C/V mappings for system clipboard
- Supports both Vim and Neovim

**Location**: `playbooks/roles/env_setup/tasks/main.yml`

### 3. Required Packages

The playbook now installs:
- `vim-gtk3` - Vim compiled with clipboard support (+clipboard)
- `xclip` - Clipboard utilities for X11
- `wl-clipboard` - Clipboard utilities for Wayland

**Location**: `playbooks/after_format.yaml`

## How to Use

### Automatic Installation

When you run the playbook, everything is configured automatically:

```bash
make run_local
# OR
ansible-playbook playbooks/after_format.yaml --ask-become-pass
```

The `x11_auth` role is part of the core setup and will:
1. Grant immediate X server access to the `aleph` user
2. Configure persistent startup scripts
3. Set up Vim clipboard integration

### Manual Application (If Needed)

If you're experiencing the issue right now, run this immediately:

```bash
# From your graphical session user (not aleph)
xhost +si:localuser:aleph
```

Then as `aleph`:
```bash
# Verify DISPLAY is set
echo $DISPLAY  # Should show :0 or :1

# Test clipboard
echo test | xclip -selection clipboard
xclip -o -selection clipboard

# Test in Vim
vim
# Press: i
# Type some text
# Press: Esc
# Press: V (visual line mode)
# Press: y (yank/copy)
# The text should now be in your system clipboard
```

### For Persistent Configuration

The playbook creates `/etc/profile.d/x11-auth-secondary-users.sh` which runs automatically on login. To make it take effect:

1. **Option A**: Log out and log back in to your graphical session
2. **Option B**: Source the script manually:
   ```bash
   source /etc/profile.d/x11-auth-secondary-users.sh
   ```

## Verification Steps

### 1. Check Vim Clipboard Support
```bash
vim --version | grep clipboard
```
Should show `+clipboard` and `+xterm_clipboard` (not `-clipboard`).

### 2. Check DISPLAY Environment
```bash
# As aleph user
echo $DISPLAY
```
Should show something like `:0` or `:1`, not empty.

### 3. Test X Server Access
```bash
# As aleph user
xhost
```
Should list allowed connections including `localuser:aleph`.

### 4. Test Clipboard Tools
```bash
# As aleph user
echo "test message" | xclip -selection clipboard
xclip -o -selection clipboard
```
Should output "test message".

### 5. Test Vim Clipboard
```bash
# As aleph user
vim
```
In Vim:
1. Type: `:set clipboard?` - should show `clipboard=unnamedplus`
2. Visual select text and press `y`
3. Switch to another app and paste (Ctrl+V) - should paste the Vim text

## Troubleshooting

### Still Getting Authorization Errors?

1. **Ensure you're in a graphical session**:
   ```bash
   echo $DISPLAY
   ```
   If empty, open a terminal within your desktop environment.

2. **Manually grant access**:
   ```bash
   # As the graphical session owner
   xhost +si:localuser:aleph
   ```

3. **Check the script exists**:
   ```bash
   cat /etc/profile.d/x11-auth-secondary-users.sh
   ```

4. **Log out and back in**: The persistent configuration activates on graphical session start.

### Vim Still Not Copying to Clipboard?

1. **Verify Vim has clipboard support**:
   ```bash
   vim --version | grep +clipboard
   ```
   If it shows `-clipboard`, you need `vim-gtk3`:
   ```bash
   sudo apt-get install -y vim-gtk3
   sudo update-alternatives --config vim  # Select vim.gtk3
   ```

2. **Check .vimrc configuration**:
   ```bash
   grep clipboard ~/.vimrc
   ```
   Should contain `set clipboard=unnamedplus`.

3. **Source the vimrc**:
   ```vim
   :source ~/.vimrc
   ```
   Or restart Vim.

4. **Try explicit clipboard register**:
   In Vim, select text and press `"+y` instead of just `y`.

### In tmux?

Add to `~/.tmux.conf`:
```tmux
set -g set-clipboard on
```
Then reload tmux config or restart tmux.

### On Wayland?

Ensure `wl-clipboard` is installed:
```bash
sudo apt-get install -y wl-clipboard
```

Test with:
```bash
echo test | wl-copy
wl-paste
```

### SSH Session?

If you're SSH'ing as aleph:
- Use X11 forwarding: `ssh -X aleph@hostname`
- OR use the terminal on the local desktop instead

## Files Modified/Created

### New Role
- `playbooks/roles/x11_auth/` - Complete new role for X11 authorization
  - `tasks/main.yml` - Main automation tasks
  - `defaults/main.yml` - Default variables
  - `templates/x11-auth-secondary-users.sh.j2` - Startup script template
  - `templates/x11-auth.service.j2` - Systemd service template
  - `README.md` - Role documentation
  - `meta/main.yml` - Role metadata
  - `molecule/` - Testing configuration

### Modified Files
- `playbooks/after_format.yaml` - Added x11_auth role to core setup
- `playbooks/after_format.yaml` - Added wl-clipboard package
- `playbooks/roles/env_setup/tasks/main.yml` - Added Vim/Neovim clipboard configuration

### Created at Runtime
- `/etc/profile.d/x11-auth-secondary-users.sh` - Auto-run on login
- `~/.config/systemd/user/x11-auth.service` - Alternative systemd service
- `~/.vimrc` - Clipboard configuration (ANSIBLE MANAGED BLOCK)

## Technical Details

### Why `xhost +si:localuser:aleph`?

This command grants X server access specifically to the local user `aleph`. It's secure because:
- `si:localuser:` restricts access to local users only (not network)
- It doesn't use the insecure `xhost +` (which allows anyone)
- It's limited to specific usernames

### Alternative: XAUTHORITY Sharing

Another approach is sharing the `~/.Xauthority` file, but this is more complex and less secure. The `xhost` method is simpler and sufficient for local user switching.

### Wayland Considerations

Modern Ubuntu uses Wayland by default, but it runs XWayland for X11 compatibility. The `xhost` command still works through XWayland, and `wl-clipboard` provides native Wayland clipboard access.

## Related Issues

- [Issue #3: aleph user doesn't have permission for X server](https://github.com/gonzfe05/ansible/issues/3)

## Testing

To test the new role in isolation:

```bash
cd playbooks/roles/x11_auth
molecule test
```

To test the full playbook in a VM:

```bash
make test-vm-core
```

## Security Considerations

The `xhost +si:localuser:<username>` method is secure for local user switching because:
1. Only specific local users are granted access (not network)
2. It requires physical or local SSH access to the machine
3. The user must already have sudo/system access to switch users
4. It doesn't compromise the X server security model

For production environments with stricter security requirements, consider:
- Using separate graphical sessions per user
- Implementing PolicyKit rules for specific GUI applications
- Using containerization or virtualization for isolation

## Future Improvements

Potential enhancements:
- [ ] Auto-detect all sudo users and grant access
- [ ] Add option to use XAUTHORITY sharing instead
- [ ] Support for multiple display servers
- [ ] Integration with display manager (GDM/LightDM) configuration
- [ ] Automated testing in graphical VM environment

## References

- [Xhost Manual](https://www.x.org/releases/X11R7.7/doc/man/man1/xhost.1.xhtml)
- [Vim Clipboard Documentation](https://vimhelp.org/options.txt.html#%27clipboard%27)
- [X11 Security](https://www.x.org/releases/X11R7.6/doc/xorg-docs/security/security.html)

---

**Status**: ✅ Fixed in playbook  
**Last Updated**: 2025-10-21  
**Author**: gonzfe05

