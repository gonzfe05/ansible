# runpodctl Role

Installs and configures `runpodctl`, the RunPod CLI tool for managing GPU pods and high-speed file transfers.

## What it does

- Downloads the runpodctl binary from GitHub releases
- Installs it to `/usr/local/bin/runpodctl`
- Configures the API key (if credentials file exists)

## Requirements

None.

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `runpodctl_version` | `1.14.15` | Version of runpodctl to install |
| `runpodctl_arch` | `amd64` | Architecture (amd64 or arm64) |

## Credentials

The role looks for an encrypted credentials file at `files/runpodctl_credentials.yml`.

### Creating the credentials file

1. Create the file with your API key:
```yaml
---
api_key: "YOUR_RUNPOD_API_KEY"
```

2. Get your API key from [RunPod Settings](https://www.runpod.io/console/user/settings)

3. Encrypt the file:
```bash
ansible-vault encrypt playbooks/roles/runpodctl/files/runpodctl_credentials.yml
```

## Tags

Use `--tags runpodctl` to run only this role.

## Example Usage

```bash
# Run just this role
ansible-playbook playbooks/after_format.yaml --tags runpodctl

# Skip this role
ansible-playbook playbooks/after_format.yaml --skip-tags runpodctl
```

## Testing

```bash
cd playbooks/roles/runpodctl
molecule test
```
