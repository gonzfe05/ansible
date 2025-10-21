SSH Role
========

Comprehensive SSH management role that handles both SSH client (outbound connections) and SSH server (inbound connections) configuration.

Features
--------

### SSH Client (Outbound Connections)
- Installs and manages SSH private and public keys
- Configures SSH agent for automatic key management
- Sets up persistent SSH agent across shell sessions
- Configures SSH client for GitHub operations
- Automatically adds SSH keys to the agent
- Creates SSH config for GitHub with proper settings
- Enables outbound SSH connections (e.g., to GitHub, remote servers)

### SSH Server (Inbound Connections) - Optional
- Installs and configures OpenSSH server
- Enables and starts the SSH daemon
- Configures SSH server for secure remote access
- Optimizes settings for remote development (VSCode/Cursor)
- Configures keep-alive settings to prevent disconnections
- Enables X11 forwarding for GUI applications
- Allows the machine to accept inbound SSH connections

Requirements
------------

- ansible
- molecule[docker] (for testing)
- ansible-lint (for linting)
- openssh-client (for client features)
- openssh-server (for server features, installed automatically when enabled)
- SSH key files (id_rsa and id_rsa.pub) in the role's files directory

Role Variables
--------------

### SSH Client Variables

- `source_key`: Name of the private key file (default: "id_rsa")
- `source_key_pub`: Name of the public key file (default: "id_rsa.pub")  
- `dest_key_private`: Destination path for private key (default: "{{ ansible_env.HOME }}/.ssh/id_rsa")
- `dest_key_pub`: Destination path for public key (default: "{{ ansible_env.HOME }}/.ssh/id_rsa.pub")

### SSH Server Variables

- `ssh_server_enabled`: Enable SSH server installation and configuration (default: false)
- `ssh_server_permit_root_login`: Allow root login via SSH (default: "no")
- `ssh_server_pubkey_authentication`: Enable public key authentication (default: "yes")
- `ssh_server_password_authentication`: Enable password authentication (default: "yes")
- `ssh_server_x11_forwarding`: Enable X11 forwarding (default: "yes")
- `ssh_server_client_alive_interval`: Seconds between keepalive messages (default: 60)
- `ssh_server_client_alive_count_max`: Max keepalive messages without response (default: 10)
- `ssh_server_packages`: List of packages to install (default: ['openssh-server'])

What This Role Does
------------------

### 1. SSH Client Configuration (Always Enabled)

**SSH Key Management:**
- Creates ~/.ssh directory with proper permissions (700)
- Copies SSH private key with secure permissions (600)
- Copies SSH public key with appropriate permissions (644)
- Adds public key to user's authorized_keys for local access

**SSH Agent Setup:**
- Kills any existing SSH agents to avoid conflicts
- Starts a new SSH agent and saves environment to ~/.ssh/ssh-agent-env
- Automatically adds SSH private key to the agent
- Verifies SSH keys are properly loaded

**Persistent Agent Configuration:**
- Adds SSH agent auto-start script to ~/.bashrc
- Adds SSH agent auto-start script to ~/.zshrc (if exists)
- Ensures agent survives shell restarts and reconnections
- Automatically loads keys when starting new shells

**GitHub Integration:**
- Creates SSH config file with GitHub-specific settings
- Configures proper identity file and connection options
- Adds github.com to known hosts automatically
- Enables AddKeysToAgent for automatic key loading

**Git Configuration:**
- The role works with git-setup tasks to configure git for SSH
- Ensures git uses SSH instead of HTTPS for GitHub operations

### 2. SSH Server Configuration (When Enabled)

**Server Installation:**
- Installs openssh-server package
- Enables SSH service to start on boot
- Starts the SSH daemon immediately

**Server Security Configuration:**
- Disables root login by default (configurable)
- Enables public key authentication
- Allows password authentication (can be disabled after key setup)
- Creates backup of sshd_config before modifications

**Remote Development Optimization:**
- Configures ClientAliveInterval to keep connections alive
- Prevents timeouts during idle periods
- Enables X11 forwarding for GUI applications
- Optimized for VSCode/Cursor remote development

**Service Management:**
- Automatically restarts SSH service when configuration changes
- Provides helpful connection information after setup
- Shows commands to connect from remote clients

Dependencies
------------

This role requires SSH key files to be present in the `files/` directory:
- `files/id_rsa` (private key)
- `files/id_rsa.pub` (public key)

Example Playbooks
----------------

### Basic Usage (Client Only)

```yaml
- name: Setup SSH Client
  hosts: localhost
  roles:
    - role: ssh
      become: yes
      become_user: myuser
```

### With SSH Server Enabled

```yaml
- name: Setup SSH Client and Server
  hosts: localhost
  roles:
    - role: ssh
      vars:
        ssh_server_enabled: true
      become: yes
      become_user: myuser
```

### Complete Setup with Custom Configuration

```yaml
- name: Full SSH Setup
  hosts: localhost
  roles:
    - role: apt_installs
      vars:
        apt_installs_custom:
          - openssh-client
      become: true
      become_user: root
    
    - role: ssh
      vars:
        ssh_server_enabled: true
        ssh_server_password_authentication: "no"  # Disable after key setup
        ssh_server_permit_root_login: "no"
        ssh_server_x11_forwarding: "yes"
      become: yes
      become_user: myuser
```

### Remote Development Server Setup

```yaml
- name: Setup Remote SSH Server for VSCode/Cursor
  hosts: localhost
  roles:
    - role: apt_installs
      vars:
        apt_installs_custom:
          - git
          - build-essential
          - python3
          - python3-pip
          - curl
          - wget
      become: true
      become_user: root
    
    - role: ssh
      vars:
        ssh_server_enabled: true
      become: yes
      become_user: developer
    
    - role: vscode
      become: true
      become_user: root
```

Tags
----

The role supports the following tags for selective execution:

- `ssh-server`: Run only server-related tasks
- `packages`: Install only packages
- `service`: Configure only the service
- `config`: Update only configuration files

Example usage:
```bash
# Install and configure only the SSH server
ansible-playbook playbook.yml --tags ssh-server

# Update only SSH server configuration
ansible-playbook playbook.yml --tags config
```

Testing
-------

The role includes comprehensive molecule tests that verify:
- SSH client installation and availability
- SSH directory and key file creation
- SSH agent environment file creation
- SSH config file for GitHub
- Shell integration (bashrc/zshrc)
- SSH agent functionality
- GitHub SSH connection (requires valid key in GitHub account)
- SSH server installation and configuration (when enabled)
- SSH service status and availability

Use the included test script to verify SSH agent setup:
```bash
./scripts/test-ssh-agent.sh
```

Run molecule tests:
```bash
cd playbooks/roles/ssh
molecule test
```

After Setup - Connecting to Your Machine
----------------------------------------

### Finding Your IP Address

On the machine running the SSH server:
```bash
# Show all IP addresses
ip addr show

# Show primary IP address
hostname -I

# Show IP for specific interface
ip addr show eth0
```

### Connecting from VSCode

1. Install the "Remote - SSH" extension
2. Press `F1` or `Ctrl+Shift+P`
3. Type "Remote-SSH: Connect to Host"
4. Enter: `username@remote-server-ip`
5. Select the platform (Linux/macOS/Windows)
6. Enter password or use SSH key

### Connecting from Cursor

1. Click on the remote indicator in the bottom-left corner
2. Select "Connect to Host"
3. Enter: `username@remote-server-ip`
4. Follow the connection prompts

### Setting Up SSH Keys for Remote Access

On your **local machine** (the one you'll connect from):

```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy your public key to the remote server
ssh-copy-id username@remote-server-ip

# Or manually copy it
cat ~/.ssh/id_ed25519.pub | ssh username@remote-server-ip "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

After setting up keys, you can disable password authentication for better security:
```yaml
- role: ssh
  vars:
    ssh_server_enabled: true
    ssh_server_password_authentication: "no"
```

Security Considerations
----------------------

### After Initial Setup

1. **Set up SSH key authentication** and disable password authentication:
   ```bash
   sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
   sudo systemctl restart ssh
   ```

2. **Configure a firewall**:
   ```bash
   sudo ufw allow ssh
   sudo ufw enable
   ```

3. **Change default SSH port** (optional):
   - Edit `/etc/ssh/sshd_config`
   - Change `Port 22` to a custom port
   - Update firewall rules accordingly
   - Restart SSH service

4. **Monitor SSH access**:
   ```bash
   # View SSH authentication logs
   sudo journalctl -u ssh -n 100
   
   # View failed login attempts
   sudo grep "Failed password" /var/log/auth.log
   ```

### Security Best Practices

- ✅ Always use SSH keys instead of passwords
- ✅ Disable root login via SSH
- ✅ Use fail2ban to prevent brute force attacks
- ✅ Keep SSH server updated
- ✅ Use strong passphrases for SSH keys
- ✅ Regularly audit SSH access logs
- ❌ Don't expose SSH to the internet without protection
- ❌ Don't use default port 22 for internet-facing servers
- ❌ Don't share private keys

Troubleshooting
--------------

### SSH Client Issues

**SSH Agent Not Starting:**
- Check if ~/.ssh/ssh-agent-env file exists and has proper permissions
- Verify SSH private key exists and has correct permissions (600)
- Check shell startup files (.bashrc/.zshrc) for SSH agent configuration

**GitHub Authentication Fails:**
- Ensure your SSH public key is added to your GitHub account
- Verify SSH config file exists at ~/.ssh/config
- Test connection manually: `ssh -T git@github.com`

**Git Operations Still Use HTTPS:**
- Check git configuration: `git config --global --get url."git@github.com:".insteadOf`
- Should return: `https://github.com/`
- Re-run git-setup tasks if needed

### SSH Server Issues

**SSH Service Not Starting:**
```bash
# Check service status
sudo systemctl status ssh

# View detailed logs
sudo journalctl -u ssh -n 50

# Test configuration
sudo sshd -t
```

**Connection Refused:**
```bash
# Ensure SSH is running
sudo systemctl start ssh

# Check if port 22 is listening
sudo ss -tlnp | grep :22

# Check firewall
sudo ufw status
```

**Can't Connect from VSCode/Cursor:**

1. Test SSH connection manually:
   ```bash
   ssh username@remote-server-ip
   ```

2. Check SSH configuration:
   ```bash
   sudo sshd -t
   ```

3. Verify permissions:
   ```bash
   ls -la ~/.ssh
   # .ssh directory should be 700
   # authorized_keys should be 600
   ```

4. Check server logs:
   ```bash
   sudo tail -f /var/log/auth.log
   ```

**Permission Denied:**
- Verify your public key is in ~/.ssh/authorized_keys on the server
- Check file permissions (authorized_keys should be 600)
- Ensure .ssh directory permissions are 700
- Check SELinux/AppArmor if enabled

**Connection Keeps Dropping:**
- Increase ClientAliveInterval and ClientAliveCountMax values
- Check network stability
- Review firewall rules that might be timing out connections

Related Roles
------------

- `users` - Create and manage users with sudo access
- `vscode` - Install VSCode CLI for remote development
- `apt_installs` - Install additional packages
- `dotfiles` - Set up shell configuration and dotfiles
- `shell` - Configure shell environment

Migrating from remote_ssh_server.yaml
------------------------------------

If you were using the separate `remote_ssh_server.yaml` playbook, you can now use this role instead:

**Old way:**
```yaml
- name: Setup Remote SSH Server
  hosts: localhost
  roles:
    - role: apt_installs
      vars:
        apt_installs_custom: [openssh-server, git, build-essential, ...]
    - role: vscode
  tasks:
    - name: Configure SSH...
      # ... manual SSH configuration
```

**New way:**
```yaml
- name: Setup Remote SSH Server
  hosts: localhost
  roles:
    - role: apt_installs
      vars:
        apt_installs_custom: [git, build-essential, ...]  # openssh-server installed by ssh role
    - role: ssh
      vars:
        ssh_server_enabled: true
    - role: vscode
```

The SSH role now handles both client and server configuration automatically!

License
-------

MIT

Author Information
------------------

Created for managing SSH client and server configuration in development environments, with special focus on remote development via VSCode and Cursor.
