# Vault Password Support in VM Testing

## Overview

The VM testing infrastructure now fully supports Ansible vault-encrypted files. You can pass your vault password file to decrypt encrypted SSH keys, AWS credentials, and ngrok tokens during testing.

## Quick Start

```bash
# Create vault password file
echo "your-vault-password" > ~/.vault_pass.txt
chmod 600 ~/.vault_pass.txt

# Use with VM tests
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm-core
```

## Methods to Provide Vault Password

### Method 1: Environment Variable (Recommended)

```bash
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm-core
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm-keep
```

**Advantages**:
- Clean and standard (follows Ansible conventions)
- Works across multiple commands
- Easy to use in CI/CD

### Method 2: Make Variable

```bash
make test-vm vault_pass_file=~/.vault_pass.txt
make test-vm-core vault_pass_file=~/.vault_pass.txt
make run_local vault_pass_file=~/.vault_pass.txt
```

**Advantages**:
- Explicit and visible
- Easy to override per command

### Method 3: Absolute Path

```bash
make test-vm vault_pass_file=/home/fer/.vault_password
```

**Advantages**:
- No tilde expansion issues
- Works with any path

## How It Works

1. **Makefile** reads `ANSIBLE_VAULT_PASSWORD_FILE` or `vault_pass_file` parameter
2. **Script** expands tilde (`~`) to your actual home directory path
3. **Transfer** securely pipes the vault password file to the VM
4. **Ansible** uses `--vault-password-file` to decrypt encrypted files
5. **Cleanup** (vault password file is removed with VM)

## What Gets Decrypted

### SSH Role
- `playbooks/roles/ssh/files/id_rsa` (private key)
- Required for SSH client setup and repos cloning

### AWS Role
- `playbooks/roles/aws/files/aws_credentials.yml`
- Contains AWS access keys

### Ngrok Role  
- `playbooks/roles/ngrok/files/ngrok_credentials.yml`
- Contains ngrok authtoken

## Testing Without Vault Password

If you don't have encrypted files or want to test without them:

### Option 1: Skip Encrypted Roles
```bash
EXTRA_ARGS="--skip-tags ssh,repos,aws,ngrok" make test-vm-core
```

### Option 2: Provide Unencrypted Files
```bash
# Copy your unencrypted SSH keys (for testing only!)
cp ~/.ssh/id_rsa playbooks/roles/ssh/files/id_rsa
cp ~/.ssh/id_rsa.pub playbooks/roles/ssh/files/id_rsa.pub

# Run test without vault password
make test-vm-core

# Don't commit unencrypted keys!
git status  # Ensure they're not staged
```

## Security Considerations

### ✅ Safe Practices

1. **Never commit vault password file**:
   ```bash
   # Add to .gitignore
   echo ".vault_pass.txt" >> .gitignore
   echo "*.vault_pass*" >> .gitignore
   ```

2. **Secure file permissions**:
   ```bash
   chmod 600 ~/.vault_pass.txt
   ```

3. **Use different passwords** for different environments:
   ```bash
   ~/.vault_pass_dev.txt   # Development
   ~/.vault_pass_prod.txt  # Production
   ```

4. **Clean up** after testing:
   ```bash
   # Vault file is automatically removed when VM is destroyed
   multipass delete ansible-test && multipass purge
   ```

### ❌ Unsafe Practices

- ❌ Committing `.vault_pass.txt` to git
- ❌ World-readable vault password files (use `chmod 600`)
- ❌ Hardcoding passwords in scripts
- ❌ Sharing vault password files via insecure channels

## Troubleshooting

### Issue: "Vault password file not found"

```
⚠️  Vault password file not found: /home/fer/.vault_pass.txt
⚠️  Continuing without vault password - encrypted files will fail to decrypt
```

**Solution**: Create the file or use correct path
```bash
# Check if file exists
ls -la ~/.vault_pass.txt

# Create if missing
echo "your-password" > ~/.vault_pass.txt
chmod 600 ~/.vault_pass.txt
```

### Issue: "A vault password or secret must be specified to decrypt"

```
fatal: [localhost]: FAILED! =>
  msg: A vault password or secret must be specified to decrypt /path/to/file
```

**Solution**: You forgot to pass the vault password file
```bash
# Add vault password file
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm-core
```

### Issue: Tilde (~) not expanding

**Solution**: The script handles this automatically now
```bash
# All of these work:
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm
ANSIBLE_VAULT_PASSWORD_FILE=$HOME/.vault_pass.txt make test-vm
vault_pass_file=/home/fer/.vault_pass.txt make test-vm
```

### Issue: Wrong vault password

```
ERROR! Decryption failed (no vault secrets would found that could decrypt)
```

**Solution**: Verify your vault password
```bash
# Test decryption locally
ansible-vault view playbooks/roles/ssh/files/id_rsa \
  --vault-password-file ~/.vault_pass.txt

# If it fails, your password is wrong
```

## Examples

### Example 1: Complete Test with Vault

```bash
# Create password file
echo "MySecurePassword123" > ~/.vault_pass.txt
chmod 600 ~/.vault_pass.txt

# Test syntax
make test-vm-syntax

# Test with vault
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm-core

# Full test
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm

# Run locally
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make run_local
```

### Example 2: Different Password Files

```bash
# Development environment
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass_dev.txt make test-vm-core

# Production environment  
ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass_prod.txt make test-vm
```

### Example 3: CI/CD Usage

```bash
# In your CI/CD pipeline (GitHub Actions, GitLab CI, etc.)
# Set ANSIBLE_VAULT_PASSWORD as a secret, then:

echo "$ANSIBLE_VAULT_PASSWORD" > /tmp/vault_pass
chmod 600 /tmp/vault_pass

ANSIBLE_VAULT_PASSWORD_FILE=/tmp/vault_pass make test-vm

rm /tmp/vault_pass  # Clean up
```

## Integration with Existing Tools

### With ansible-playbook directly

```bash
# The VM will use this internally:
ansible-playbook playbooks/after_format.yaml \
  --vault-password-file ~/.vault_pass.txt
```

### With ansible-vault

```bash
# View encrypted file
ansible-vault view playbooks/roles/ssh/files/id_rsa \
  --vault-password-file ~/.vault_pass.txt

# Edit encrypted file
ansible-vault edit playbooks/roles/ssh/files/id_rsa \
  --vault-password-file ~/.vault_pass.txt

# Encrypt a new file
ansible-vault encrypt playbooks/roles/ssh/files/new_key \
  --vault-password-file ~/.vault_pass.txt
```

## Summary

✅ **Vault password support is fully integrated**  
✅ **Multiple methods to provide password**  
✅ **Automatic tilde expansion**  
✅ **Secure transfer to VM**  
✅ **Clean documentation**  
✅ **Works with all test targets**  

---

**Updated**: October 21, 2025  
**Status**: ✅ Production Ready
