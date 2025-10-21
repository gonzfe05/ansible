.PHONY: run test clean-test-cache test-vm test-vm-keep test-vm-core test-vm-syntax


# Ubuntu version configuration
ubuntu_major ?= 24
ubuntu_minor ?= 04

# Vault password file (optional)
# Can be set via: make test-vm vault_pass_file=~/.vault_pass.txt
# Or via env var: ANSIBLE_VAULT_PASSWORD_FILE=~/.vault_pass.txt make test-vm
vault_pass_file ?= $(ANSIBLE_VAULT_PASSWORD_FILE)

# VM test configuration
vm_name ?= ansible-test
vm_cpus ?= 2
vm_mem ?= 4G
vm_disk ?= 20G

image ?= ubuntu:$(ubuntu_major).$(ubuntu_minor)

run:
	scripts/run_container.sh $(image)
install:
	scripts/install_docker.sh
	sudo scripts/install_ansible.sh
install_dev:
	scripts/install_docker.sh
	sudo scripts/install_ansible.sh
	scripts/install_molecule.sh
run_local:
	$(if $(vault_pass_file),ANSIBLE_VAULT_PASSWORD_FILE=$(vault_pass_file),) ansible-playbook playbooks/after_format.yaml $(if $(vault_pass_file),,--ask-vault-pass) --ask-become-pass
test:
	$(if $(vault_pass_file),ANSIBLE_VAULT_PASSWORD_FILE=$(vault_pass_file),) UBUNTU_MAJOR=$(ubuntu_major) UBUNTU_MINOR=$(ubuntu_minor) scripts/test_all_roles.sh
clean-test-cache:
	@echo "🧹 Cleaning test cache..."
	@rm -f .molecule_test_cache
	@echo "✅ Test cache cleared"

# VM-based full playbook testing
test-vm:
	@echo "🚀 Running full playbook test in ephemeral VM..."
	@$(if $(vault_pass_file),echo "📝 Using vault password file: $(vault_pass_file)",echo "⚠️  No vault password file specified (encrypted files will fail)")
	VM_NAME=$(vm_name) VM_CPUS=$(vm_cpus) VM_MEM=$(vm_mem) VM_DISK=$(vm_disk) \
	UBUNTU_VERSION=$(ubuntu_major).$(ubuntu_minor) \
	VAULT_PASS_FILE=$(vault_pass_file) \
	scripts/test_vm.sh

# VM test with keep VM for debugging
test-vm-keep:
	@echo "🚀 Running playbook test in VM (keep VM after run)..."
	@$(if $(vault_pass_file),echo "📝 Using vault password file: $(vault_pass_file)",echo "⚠️  No vault password file specified (encrypted files will fail)")
	VM_NAME=$(vm_name) VM_CPUS=$(vm_cpus) VM_MEM=$(vm_mem) VM_DISK=$(vm_disk) \
	UBUNTU_VERSION=$(ubuntu_major).$(ubuntu_minor) KEEP_VM=true \
	VAULT_PASS_FILE=$(vault_pass_file) \
	scripts/test_vm.sh

# VM test with only core tags
test-vm-core:
	@echo "🚀 Running core playbook test in ephemeral VM..."
	@$(if $(vault_pass_file),echo "📝 Using vault password file: $(vault_pass_file)",echo "⚠️  No vault password file specified (encrypted files will fail)")
	VM_NAME=$(vm_name) VM_CPUS=$(vm_cpus) VM_MEM=$(vm_mem) VM_DISK=$(vm_disk) \
	UBUNTU_VERSION=$(ubuntu_major).$(ubuntu_minor) \
	EXTRA_ARGS="--tags core -e ssh_server_enabled=false" \
	VAULT_PASS_FILE=$(vault_pass_file) \
	scripts/test_vm.sh

# Syntax check (local, no VM)
test-vm-syntax:
	@echo "🔍 Running syntax check..."
	@ansible-playbook playbooks/after_format.yaml --syntax-check
	@echo "✅ Syntax check passed"
	@echo ""
	@echo "📋 Available tags:"
	@ansible-playbook playbooks/after_format.yaml --list-tags
	@echo ""
	@echo "📝 Tasks to run:"
	@ansible-playbook playbooks/after_format.yaml --list-tasks
