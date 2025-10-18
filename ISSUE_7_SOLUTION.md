# Issue #7 Solution: Ngrok Role Implementation

## Overview

Successfully implemented the ngrok role as requested in [Issue #7](https://github.com/gonzfe05/ansible/issues/7). The role installs and configures ngrok for SSH tunneling on port 22.

## What Was Created

### Role Structure

```
playbooks/roles/ngrok/
├── defaults/
│   └── main.yml              # Default variables
├── meta/
│   └── main.yml              # Role metadata
├── molecule/
│   └── default/
│       ├── converge.yml      # Test playbook
│       ├── molecule.yml      # Test configuration
│       └── verify.yml        # Test verification
├── tasks/
│   └── main.yml              # Main tasks
├── templates/
│   └── ngrok.yml.j2          # Configuration template
└── README.md                 # Documentation

```

### Key Features Implemented

1. **Ngrok Installation via APT:**
   - Adds ngrok repository signing key
   - Configures ngrok APT repository
   - Installs ngrok package
   - Verifies installation

2. **Configuration Setup:**
   - Creates `~/.config/ngrok/` directory
   - Generates `ngrok.yml` configuration file
   - Configures SSH tunnel on TCP port 22
   - Sets up logging

3. **Testing:**
   - Comprehensive Molecule tests
   - Verifies package installation
   - Checks binary availability
   - Validates configuration file

## Usage

### Basic Usage

Add the ngrok role to your playbook:

```yaml
- name: Install and configure ngrok
  hosts: all
  roles:
    - role: ngrok
      vars:
        ngrok_authtoken: "your_ngrok_authtoken_here"
      become: true
      become_user: fer
```

### Adding to after_format.yaml

To integrate ngrok into the existing `after_format.yaml` playbook:

```yaml
- name: after_format
  hosts: localhost
  roles:
    # ... existing roles ...
    - role: ssh
      become: true
      become_user: aleph
      tags: ['core']
    - role: ngrok
      become: true
      become_user: aleph
      tags: ['core', 'ngrok']
    # ... more roles ...
```

### Running the Role

#### Option 1: Using Encrypted Credentials File (Recommended - Matches Project Pattern)

This method follows the same pattern as your AWS role:

```bash
cd /home/fer/ansible

# Create credentials file from example
cp playbooks/roles/ngrok/files/ngrok_credentials.yml.example \
   playbooks/roles/ngrok/files/ngrok_credentials.yml

# Edit and add your actual token
vi playbooks/roles/ngrok/files/ngrok_credentials.yml

# Encrypt the file
ansible-vault encrypt playbooks/roles/ngrok/files/ngrok_credentials.yml

# Run the playbook (no extra-vars needed!)
ansible-playbook playbooks/ngrok_setup.yaml --ask-vault-pass
```

#### Option 2: Using External Vault File

1. Create a vault file:
```bash
ansible-vault create credentials/ngrok_vault.yml
```

2. Add the token:
```yaml
ngrok_authtoken: "your_actual_token_here"
```

3. Run the playbook:
```bash
ansible-playbook playbooks/ngrok_setup.yaml --extra-vars "@credentials/ngrok_vault.yml" --ask-vault-pass
```

#### Option 3: Run with Environment Variable

```bash
export NGROK_AUTHTOKEN="your_token_here"
ansible-playbook playbooks/ngrok_setup.yaml --extra-vars "ngrok_authtoken=${NGROK_AUTHTOKEN}"
```

#### Option 4: Add to existing playbook

```bash
ansible-playbook playbooks/after_format.yaml --tags ngrok --ask-vault-pass
```

### Starting Ngrok

After installation, start ngrok SSH tunnel:

```bash
# Using the configured tunnel
ngrok start ssh

# Or directly
ngrok tcp 22
```

## Configuration

### Default Variables (defaults/main.yml)

- `ngrok_config_dir`: Configuration directory (default: `~/.config/ngrok`)
- `ngrok_config_file`: Configuration file path (default: `~/.config/ngrok/ngrok.yml`)
- `ngrok_authtoken`: Authentication token (default: empty, must be provided)
- `ngrok_version`: Version to install (default: "latest")

### Configuration File Template

The role creates `/home/fer/.config/ngrok/ngrok.yml` with:

```yaml
version: "2"
authtoken: <your_token>

tunnels:
  ssh:
    proto: tcp
    addr: 22

log_level: info
log_format: logfmt
log: /home/fer/.config/ngrok/ngrok.log
```

## Testing

### Run Molecule Tests

```bash
cd /home/fer/ansible/playbooks/roles/ngrok
molecule test
```

This will:
1. Create a Docker container
2. Install ngrok
3. Verify installation
4. Check configuration
5. Destroy the container

### Test in Your Environment

```bash
# Check ngrok is installed
which ngrok
ngrok version

# Check configuration
cat ~/.config/ngrok/ngrok.yml

# Test SSH tunnel
ngrok tcp 22
```

## Getting Your Ngrok Auth Token

1. Sign up at https://ngrok.com/
2. Go to https://dashboard.ngrok.com/get-started/your-authtoken
3. Copy your authtoken
4. Use it in the role configuration

## Security Best Practices

1. **Never commit auth tokens to version control**
2. **Use Ansible Vault** to encrypt sensitive data:
   ```bash
   ansible-vault encrypt credentials/ngrok_vault.yml
   ```
3. **Use environment variables** for local testing
4. **Restrict file permissions**: Config file is created with mode 0600
5. **Monitor tunnel usage** through ngrok dashboard

## Troubleshooting

### Ngrok not found after installation

```bash
# Verify installation
dpkg -l | grep ngrok

# Check if ngrok is in PATH
which ngrok

# Restart shell or source profile
source ~/.bashrc  # or ~/.zshrc
```

### Authentication errors

```bash
# Check configuration file
cat ~/.config/ngrok/ngrok.yml

# Verify your token at ngrok dashboard
# Update token:
ansible-playbook playbooks/setup_ngrok.yaml --extra-vars "ngrok_authtoken=NEW_TOKEN"
```

### Tunnel connection issues

```bash
# Check ngrok logs
cat ~/.config/ngrok/ngrok.log

# Verify SSH is running
systemctl status ssh

# Check port 22 is not blocked
sudo netstat -tulpn | grep :22
```

## Files Created

1. `/home/fer/ansible/playbooks/roles/ngrok/tasks/main.yml` - Main tasks
2. `/home/fer/ansible/playbooks/roles/ngrok/templates/ngrok.yml.j2` - Config template
3. `/home/fer/ansible/playbooks/roles/ngrok/defaults/main.yml` - Default variables
4. `/home/fer/ansible/playbooks/roles/ngrok/meta/main.yml` - Role metadata
5. `/home/fer/ansible/playbooks/roles/ngrok/README.md` - Documentation
6. `/home/fer/ansible/playbooks/roles/ngrok/molecule/default/molecule.yml` - Test config
7. `/home/fer/ansible/playbooks/roles/ngrok/molecule/default/converge.yml` - Test playbook
8. `/home/fer/ansible/playbooks/roles/ngrok/molecule/default/verify.yml` - Test verification

## Next Steps

1. Get your ngrok authtoken from https://dashboard.ngrok.com/
2. Store it securely using Ansible Vault
3. Add the ngrok role to your playbooks as needed
4. Run the playbook to install and configure ngrok
5. Start ngrok with `ngrok start ssh` or `ngrok tcp 22`

## Issue Resolution

This implementation resolves all requirements from Issue #7:

- ✅ Ngrok installed via APT using the provided commands
- ✅ Configuration file created at `/home/fer/.config/ngrok/ngrok.yml`
- ✅ SSH tunnel configured for TCP port 22
- ✅ Role integrated into Ansible playbook structure
- ✅ Comprehensive testing with Molecule
- ✅ Full documentation provided

## References

- [Ngrok Documentation](https://ngrok.com/docs)
- [Ngrok Dashboard](https://dashboard.ngrok.com/)
- [Issue #7](https://github.com/gonzfe05/ansible/issues/7)

