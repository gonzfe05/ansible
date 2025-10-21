# X11 Authorization Role

This role grants X server access to secondary users (like `aleph`) so they can run GUI applications and use clipboard features when switching users with `su` or `sudo su`.

## Problem

When you switch to a different user in a terminal session, the new user doesn't have permission to access the X server of the graphical session. This causes:

- GUI applications fail with "Authorization required, but no authorization protocol specified"
- Clipboard operations (like Vim `"+y` or `xclip`) fail with "Can't open display"
- VSCode and other GUI apps won't launch

## Solution

This role automatically grants X server access to specified users using `xhost +si:localuser:<username>`, and makes this configuration persistent across reboots.

## Requirements

- A graphical desktop environment (X11 or XWayland)
- `xhost` command (usually provided by `x11-xserver-utils` package)
- `xclip` or `wl-clipboard` for clipboard operations

## Role Variables

Available variables with their default values:

```yaml
# List of users to grant X server access
x11_auth_users:
  - aleph

# Whether to make the configuration persistent (auto-run on login)
x11_auth_persistent: true

# Primary user who owns the graphical session (auto-detected)
x11_auth_primary_user: "{{ ansible_env.SUDO_USER | default(lookup('env', 'USER')) }}"
```

## Dependencies

None.

## Example Playbook

```yaml
- hosts: localhost
  roles:
    - role: x11_auth
      vars:
        x11_auth_users:
          - aleph
          - another_user
      become: true
```

## How It Works

The role implements multiple approaches to ensure persistence:

1. **Immediate authorization**: Runs `xhost +si:localuser:<user>` immediately during playbook execution
2. **Profile script**: Creates `/etc/profile.d/x11-auth-secondary-users.sh` to run on shell login
3. **Systemd user service**: Creates a user service for graphical session startup

## Usage

After running this role:

1. Switch to the secondary user:
   ```bash
   sudo su - aleph
   ```

2. Verify DISPLAY is set:
   ```bash
   echo $DISPLAY  # Should show something like ':0' or ':1'
   ```

3. Test clipboard:
   ```bash
   echo test | xclip -selection clipboard
   xclip -o -selection clipboard
   ```

4. Use Vim with clipboard:
   - Add `set clipboard=unnamedplus` to `~/.vimrc`
   - Now `v` + `y` will copy to system clipboard

## Troubleshooting

### Still getting authorization errors?

1. **Log out and back in**: The persistent configuration activates on graphical session start
2. **Manual grant**: Run `xhost +si:localuser:aleph` as the graphical session owner
3. **Check DISPLAY**: Run `echo $DISPLAY` - if empty, you're not in a graphical environment

### Clipboard still not working?

1. **Install clipboard tools**:
   ```bash
   sudo apt-get install -y xclip wl-clipboard vim-gtk3
   ```

2. **Configure Vim**: Add to `~/.vimrc`:
   ```vim
   set clipboard=unnamedplus
   ```

3. **Verify Vim has clipboard support**:
   ```bash
   vim --version | grep clipboard  # Should show +clipboard
   ```

### In tmux?

Add to `~/.tmux.conf`:
```tmux
set -g set-clipboard on
```

## Security Note

The `xhost +si:localuser:<username>` command only grants access to specific local users, not to any remote connections or arbitrary processes. This is a secure method for local user-to-user X server access.

## Related Issues

- [Issue #3: aleph user doesn't have permission for X server](https://github.com/gonzfe05/ansible/issues/3)

## License

MIT

## Author

gonzfe05

