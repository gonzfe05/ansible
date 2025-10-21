# SSH Role - Quick Start Guide

## TL;DR

The SSH role now handles **both client and server** SSH configuration!

```yaml
# Client only (default)
- role: ssh

# Client + Server
- role: ssh
  vars:
    ssh_server_enabled: true
```

## Common Use Cases

### 1. GitHub SSH Access (Client Only)

**What you get**: SSH keys, agent, GitHub config

```yaml
- role: ssh
  become: yes
  become_user: myuser
```

### 2. Remote Development Server (Client + Server)

**What you get**: Everything + SSH server for VSCode/Cursor

```yaml
- role: ssh
  vars:
    ssh_server_enabled: true
  become: yes
  become_user: myuser
```

After running, connect with: `ssh myuser@server-ip`

### 3. Secure Remote Server (Keys Only)

**What you get**: Server with password auth disabled

```yaml
- role: ssh
  vars:
    ssh_server_enabled: true
    ssh_server_password_authentication: "no"
  become: yes
  become_user: myuser
```

**⚠️ Important**: Set up SSH keys BEFORE disabling password auth!

```bash
# On your local machine
ssh-copy-id myuser@server-ip
```

## Key Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ssh_server_enabled` | `false` | Enable SSH server |
| `ssh_server_password_authentication` | `"yes"` | Allow passwords |
| `ssh_server_permit_root_login` | `"no"` | Allow root login |
| `ssh_server_x11_forwarding` | `"yes"` | Enable X11 |
| `ssh_server_client_alive_interval` | `60` | Keepalive seconds |

## Examples

### Example 1: Basic After-Format Setup

```yaml
- name: After Format Setup
  hosts: localhost
  roles:
    - role: ssh
      become: yes
      become_user: myuser
```

### Example 2: Remote Dev Machine

```yaml
- name: Remote Dev Server
  hosts: localhost
  roles:
    - role: apt_installs
      vars:
        apt_installs_custom: [git, build-essential, python3]
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

### Example 3: Production Server (Secure)

```yaml
- name: Production Server
  hosts: production
  roles:
    - role: ssh
      vars:
        ssh_server_enabled: true
        ssh_server_password_authentication: "no"
        ssh_server_permit_root_login: "no"
        ssh_server_client_alive_interval: 300
      become: yes
      become_user: appuser
```

## After Setup

### Find Your Server IP

```bash
hostname -I
```

### Connect from VSCode/Cursor

1. Install "Remote - SSH" extension
2. Connect to: `username@server-ip`

### Test SSH Connection

```bash
ssh username@server-ip
```

### Check SSH Service

```bash
sudo systemctl status ssh
```

## Security Checklist

- [ ] Generate SSH key: `ssh-keygen -t ed25519`
- [ ] Copy key to server: `ssh-copy-id user@server`
- [ ] Test key auth: `ssh user@server`
- [ ] Disable password auth: Set `ssh_server_password_authentication: "no"`
- [ ] Enable firewall: `sudo ufw allow ssh && sudo ufw enable`
- [ ] Monitor logs: `sudo journalctl -u ssh -f`

## Troubleshooting One-Liners

```bash
# Check if SSH server is running
sudo systemctl status ssh

# Check if port 22 is listening
sudo ss -tlnp | grep :22

# Test SSH configuration
sudo sshd -t

# View SSH logs
sudo journalctl -u ssh -n 50

# Check failed login attempts
sudo grep "Failed" /var/log/auth.log | tail -20
```

## Tags

Run specific parts only:

```bash
# Server setup only
ansible-playbook playbook.yml --tags ssh-server

# Configuration only
ansible-playbook playbook.yml --tags config
```

## More Info

- Full documentation: `README.md`
- Enhancement details: `SSH_ROLE_ENHANCEMENT.md`
- Example playbook: `../../remote_ssh_server_v2.yaml`

## Quick Decision Matrix

| I want to... | Use this config |
|--------------|-----------------|
| Connect to GitHub from my machine | `ssh_server_enabled: false` (default) |
| Connect to my machine with VSCode | `ssh_server_enabled: true` |
| Accept SSH connections | `ssh_server_enabled: true` |
| Both connect from and to my machine | `ssh_server_enabled: true` |

---

**Remember**: The SSH role does **both** client and server. Server is optional (off by default).

