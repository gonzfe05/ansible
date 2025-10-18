# Ngrok Quick Start Guide

## Installation

### Method 1: Using Encrypted Credentials File (Recommended - Matches AWS Role Pattern)

```bash
# Get your token from: https://dashboard.ngrok.com/get-started/your-authtoken

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

### Method 2: Using External Vault File

```bash
# Create vault file (first time only)
ansible-vault create credentials/ngrok_vault.yml
# Enter password when prompted
# Add this content:
# ngrok_authtoken: "your_actual_token_here"
# Save and exit

# Run the playbook with vault
ansible-playbook playbooks/ngrok_setup.yaml --extra-vars "@credentials/ngrok_vault.yml" --ask-vault-pass
```

### Method 3: Environment Variable (Quick testing)

```bash
export NGROK_AUTHTOKEN="your_token_here"
ansible-playbook playbooks/ngrok_setup.yaml --extra-vars "ngrok_authtoken=${NGROK_AUTHTOKEN}"
```

### Method 4: Command line (Quick testing)

```bash
ansible-playbook playbooks/ngrok_setup.yaml --extra-vars "ngrok_authtoken=YOUR_TOKEN_HERE"
```

## Using Ngrok

### Start SSH tunnel

```bash
# Using named tunnel from config
ngrok start ssh

# Or direct command
ngrok tcp 22
```

### Access your tunnel

Once started, ngrok will display:
```
Forwarding: tcp://X.tcp.ngrok.io:XXXXX -> localhost:22
```

Connect from anywhere:
```bash
ssh -p XXXXX fer@X.tcp.ngrok.io
```

## Configuration Location

- Config file: `~/.config/ngrok/ngrok.yml`
- Log file: `~/.config/ngrok/ngrok.log`

## Common Commands

```bash
# Check ngrok version
ngrok version

# View configuration
cat ~/.config/ngrok/ngrok.yml

# Check logs
cat ~/.config/ngrok/ngrok.log

# List available tunnels
ngrok config check
```

## Tips

1. **Free tier limitations**: Ngrok free tier has limitations on concurrent tunnels
2. **Dynamic URLs**: Free tier URLs change on each restart
3. **Keep running**: Ngrok must stay running to maintain the tunnel
4. **Background process**: Use `screen` or `tmux` to keep ngrok running:
   ```bash
   tmux new -s ngrok
   ngrok start ssh
   # Press Ctrl+B, then D to detach
   ```

## Troubleshooting

### "command not found: ngrok"
```bash
# Restart shell or source profile
source ~/.bashrc
# Or re-run the playbook
ansible-playbook playbooks/ngrok_setup.yaml --extra-vars "ngrok_authtoken=${NGROK_AUTHTOKEN}"
```

### Authentication failed
```bash
# Check your token in the dashboard
# Update configuration
cat ~/.config/ngrok/ngrok.yml
# Re-run playbook with correct token
```

### Port already in use
```bash
# Check if ngrok is already running
ps aux | grep ngrok
# Kill existing process
pkill ngrok
```

## Security Warnings

⚠️ **Important Security Considerations:**

1. Ngrok exposes your SSH port to the internet
2. Ensure you have strong SSH authentication (keys, not passwords)
3. Consider using ngrok's IP restrictions (paid feature)
4. Monitor access through ngrok dashboard
5. Stop ngrok when not needed: `pkill ngrok`

## Getting Help

- Ngrok documentation: https://ngrok.com/docs
- Role README: `/home/fer/ansible/playbooks/roles/ngrok/README.md`
- Full solution: `/home/fer/ansible/ISSUE_7_SOLUTION.md`

