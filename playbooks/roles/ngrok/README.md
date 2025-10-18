Ngrok Role
===========

Installs and configures ngrok for SSH tunneling on Linux systems.

Features
--------

- Installs ngrok via official APT repository
- Creates ngrok configuration directory
- Sets up ngrok configuration file with SSH tunnel support
- Configures ngrok for TCP tunneling on port 22 (SSH)
- Supports custom ngrok authentication tokens

Requirements
------------

- ansible
- Ubuntu/Debian-based system
- sudo privileges for package installation
- molecule[docker] (for testing)
- ansible-lint (for linting)

Role Variables
--------------

- `ngrok_config_dir`: Directory for ngrok configuration (default: `{{ ansible_env.HOME }}/.config/ngrok`)
- `ngrok_config_file`: Path to ngrok configuration file (default: `{{ ngrok_config_dir }}/ngrok.yml`)
- `ngrok_authtoken`: Ngrok authentication token (default: empty, can be provided via encrypted file, vault, or extra vars)
- `ngrok_version`: Ngrok version to install (default: "latest")

Credential Files
----------------

This role supports two methods for providing your ngrok authtoken:

### Method 1: Encrypted Credentials File (Recommended)

Create and encrypt a credentials file (similar to the AWS role):

```bash
# Create credentials file from example
cp playbooks/roles/ngrok/files/ngrok_credentials.yml.example \
   playbooks/roles/ngrok/files/ngrok_credentials.yml

# Edit and add your actual token
vi playbooks/roles/ngrok/files/ngrok_credentials.yml

# Encrypt the file
ansible-vault encrypt playbooks/roles/ngrok/files/ngrok_credentials.yml
```

The credentials file structure:
```yaml
authtoken: "your_ngrok_authtoken_here"
```

Then run your playbook normally:
```bash
ansible-playbook playbooks/ngrok_setup.yaml --ask-vault-pass
```

### Method 2: Direct Variable (Quick Testing)

Pass the token directly as an extra variable:
```bash
ansible-playbook playbooks/ngrok_setup.yaml --extra-vars "ngrok_authtoken=YOUR_TOKEN"
```

What This Role Does
-------------------

1. **Ngrok Installation:**
   - Adds ngrok APT repository signing key
   - Adds ngrok repository to system sources
   - Updates APT cache
   - Installs ngrok package
   - Verifies installation

2. **Configuration Setup:**
   - Creates ~/.config/ngrok directory
   - Generates ngrok.yml configuration file from template
   - Sets up SSH tunnel configuration (TCP on port 22)
   - Configures logging

3. **Verification:**
   - Checks ngrok version after installation
   - Verifies configuration file creation
   - Displays installation status

Dependencies
------------

None

Example Playbook
----------------

### Using Encrypted Credentials File (Recommended)

```yaml
- name: Install and configure ngrok
  hosts: all
  become: yes
  roles:
    - role: ngrok
```

Run with:
```bash
# Token will be loaded from files/ngrok_credentials.yml (encrypted)
ansible-playbook playbook.yml --ask-vault-pass
```

### Using Direct Variable

```yaml
- name: Install and configure ngrok
  hosts: all
  become: yes
  roles:
    - role: ngrok
      vars:
        ngrok_authtoken: "your_ngrok_authtoken_here"
```

### Using External Vault File

```yaml
- name: Install and configure ngrok
  hosts: all
  become: yes
  roles:
    - role: ngrok
```

Then provide the token via separate vault:
```bash
ansible-playbook playbook.yml --extra-vars "@credentials/ngrok_vault.yml" --ask-vault-pass
```

Usage
-----

After installation, you can start ngrok SSH tunnel with:

```bash
ngrok tcp 22
```

Or use the configured tunnel from the config file:

```bash
ngrok start ssh
```

Configuration File
------------------

The role creates a configuration file at `~/.config/ngrok/ngrok.yml` with the following structure:

```yaml
version: "2"
authtoken: <your_token>

tunnels:
  ssh:
    proto: tcp
    addr: 22

log_level: info
log_format: logfmt
log: ~/.config/ngrok/ngrok.log
```

Testing
-------

The role includes molecule tests that verify:
- Ngrok package installation
- Binary availability in PATH
- Configuration directory creation
- Configuration file creation with proper format
- Ngrok version command execution

Run tests with:
```bash
cd playbooks/roles/ngrok
molecule test
```

Troubleshooting
---------------

**Ngrok not found after installation:**
- Verify the package was installed: `dpkg -l | grep ngrok`
- Check if ngrok is in PATH: `which ngrok`
- Restart your shell or source your profile

**Authentication errors:**
- Ensure you've set a valid `ngrok_authtoken`
- Verify the token in the configuration file: `cat ~/.config/ngrok/ngrok.yml`
- Get your auth token from: https://dashboard.ngrok.com/get-started/your-authtoken

**Tunnel connection issues:**
- Check ngrok logs: `cat ~/.config/ngrok/ngrok.log`
- Verify port 22 is not already in use
- Ensure SSH service is running: `systemctl status ssh`

Security Notes
--------------

- Store ngrok auth tokens in Ansible Vault, not in plain text
- Restrict access to the configuration file (mode 0600)
- Monitor ngrok tunnel usage and connections
- Be aware that ngrok exposes your SSH port to the internet

License
-------

GPL-2.0-or-later

Author Information
------------------

Fernando Gonzalez (gonzfe05)

