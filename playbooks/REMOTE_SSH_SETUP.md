# Remote SSH Server Setup for VSCode/Cursor

> **✨ NEW: The SSH role now includes server functionality!**  
> We recommend using `remote_ssh_server_v2.yaml` which leverages the enhanced SSH role.  
> This guide covers both the original manual setup and the new role-based approach.

This playbook sets up a machine for remote SSH access with VSCode or Cursor IDE.

## What It Does

This playbook installs only the essential components needed to use your machine as a remote development server via SSH:

1. **SSH Server Setup**
   - Installs and configures OpenSSH server
   - Enables and starts the SSH service
   - Configures SSH for better remote development:
     - Disables root login for security
     - Enables public key authentication
     - Keeps connections alive (prevents timeout)
     - Enables X11 forwarding for GUI applications

2. **Essential Development Tools**
   - Git (required for VSCode/Cursor remote features)
   - Build tools (gcc, g++, make) for compiling native extensions
   - Python 3 and pip for Python-based extensions
   - Download utilities (curl, wget)
   - SSL certificates and GPG for secure connections

3. **VSCode CLI**
   - Installs the VSCode CLI server component
   - Enables remote development features for both VSCode and Cursor

## Prerequisites

- Ubuntu/Debian-based system
- Ansible installed on the machine
- Root/sudo access

## Usage

### Recommended: Remote SSH Server with Enhanced Features

The playbook now uses the enhanced SSH role and optionally includes ngrok tunneling:

**Basic SSH Server Setup:**
```bash
ansible-playbook playbooks/remote_ssh_server.yaml
```

**With ngrok Tunneling (for NAT/firewall bypass):**
```bash
ansible-playbook playbooks/remote_ssh_server.yaml \
  -e "enable_ngrok=true ngrok_authtoken=YOUR_TOKEN"
```

**With Custom User:**
```bash
ansible-playbook playbooks/remote_ssh_server.yaml \
  -e "setup_user=developer"
```

Benefits:
- ✅ Role-based configuration (more maintainable)
- ✅ Automatic SSH server installation and configuration
- ✅ Configurable security settings via variables
- ✅ Includes both client and server setup
- ✅ Optional ngrok tunneling for remote access through NAT
- ✅ Better testing support with molecule
- ✅ Consistent with other Ansible roles

### Run specific parts using tags:

```bash
# Install only packages
ansible-playbook playbooks/remote_ssh_server.yaml --tags packages

# Configure only SSH
ansible-playbook playbooks/remote_ssh_server.yaml --tags ssh

# Install only VSCode CLI
ansible-playbook playbooks/remote_ssh_server.yaml --tags vscode
```

## ngrok Tunneling (Optional)

If you enabled ngrok tunneling, you can access your SSH server from anywhere:

### Starting the ngrok Tunnel

```bash
ngrok tcp 22
```

This will output something like:
```
Forwarding  tcp://0.tcp.ngrok.io:12345 -> localhost:22
```

### Connecting via ngrok

```bash
ssh username@0.tcp.ngrok.io -p 12345
```

### Use Cases for ngrok
- 🏠 Access your home machine from work
- 🔒 Bypass restrictive firewalls/NAT
- 🌐 No need for port forwarding or dynamic DNS
- 🚀 Quick remote access setup

### ngrok Tips
- Get a free account at https://ngrok.com for longer session times
- Use ngrok config for persistent tunnel settings
- Consider ngrok's paid plans for custom domains and reserved addresses

## After Running the Playbook

### 1. Set up your SSH key for authentication (recommended)

On your **local machine**, generate an SSH key if you haven't already:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Copy your public key to the remote server:

```bash
ssh-copy-id username@remote-server-ip
```

### 2. Find your server's IP address

On the **remote server**:

```bash
ip addr show
# or
hostname -I
```

### 3. Connect from VSCode/Cursor

#### For VSCode:
1. Install the "Remote - SSH" extension
2. Press `F1` or `Ctrl+Shift+P`
3. Type "Remote-SSH: Connect to Host"
4. Enter: `username@remote-server-ip`

#### For Cursor:
1. Click on the remote indicator in the bottom-left corner
2. Select "Connect to Host"
3. Enter: `username@remote-server-ip`

### 4. Security Considerations

After setup, consider:

- **Disable password authentication** (after setting up SSH keys):
  ```bash
  sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
  sudo systemctl restart ssh
  ```

- **Set up a firewall**:
  ```bash
  sudo ufw allow ssh
  sudo ufw enable
  ```

- **Change the default SSH port** (optional, for additional security):
  Edit `/etc/ssh/sshd_config` and change the Port directive

## Troubleshooting

### SSH service not starting

Check the service status:
```bash
sudo systemctl status ssh
```

View SSH logs:
```bash
sudo journalctl -u ssh -n 50
```

### Connection refused

Ensure SSH is running:
```bash
sudo systemctl start ssh
```

Check if port 22 is open:
```bash
sudo ss -tlnp | grep :22
```

### VSCode/Cursor can't connect

1. Test SSH connection manually:
   ```bash
   ssh username@remote-server-ip
   ```

2. Check SSH configuration:
   ```bash
   sudo sshd -t
   ```

3. Ensure your user has proper permissions:
   ```bash
   ls -la ~/.ssh
   # .ssh directory should be 700
   # authorized_keys should be 600
   ```

## What's NOT Included

This playbook intentionally keeps the installation minimal. It does NOT include:

- User creation (use the `users` role if needed)
- SSH key management (use the `ssh` role if needed)
- Development language runtimes (Node.js, Go, R, etc.)
- Dotfiles and shell configuration
- Additional development tools

If you need these features, refer to the `after_format.yaml` playbook or use the individual roles.

## Roles Used

This playbook leverages the following existing roles:

- **`apt_installs`** - Installs all required packages (openssh-server, git, build-essential, etc.)
- **`vscode`** - Installs the VSCode CLI for remote development

### ✨ NEW: The `ssh` Role Now Supports Server Configuration!

The SSH role has been enhanced to support both client and server functionality:

**Client-side (Always Enabled):**
- Copies SSH private/public keys
- Sets up SSH agent
- Configures SSH client config for GitHub
- Client-to-server key management

**Server-side (Optional - New!):**
- Installs and starts openssh-server
- Configures the SSH daemon (`/etc/ssh/sshd_config`)
- Enables remote connections to this machine
- Configurable security settings

To enable server features, simply set `ssh_server_enabled: true` when using the role.

**Migration Example:**

Old way (manual):
```yaml
- role: apt_installs
  vars:
    apt_installs_custom: [openssh-server, ...]
tasks:
  - name: Configure SSH...
    # manual configuration
```

New way (using the ssh role):
```yaml
- role: ssh
  vars:
    ssh_server_enabled: true
    ssh_server_password_authentication: "no"
```

See `playbooks/remote_ssh_server_v2.yaml` for a complete example.

## Related Roles

- `users` - Create and manage users with sudo access
- `ssh` - Set up SSH keys and SSH agent (for connecting FROM this machine to others)
- `vscode` - Install VSCode CLI (included in this playbook)
- `apt_installs` - Install additional packages (included in this playbook)

## Extending This Playbook

You can add additional roles or customize the package list by modifying the playbook:

```yaml
- name: Install additional packages
  ansible.builtin.apt:
    name:
      - nodejs
      - docker.io
      # Add more packages here
    state: present
  become: true
  tags: ['packages']
```

