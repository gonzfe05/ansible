.PHONY: run test clean-test-cache


# Ubuntu version configuration
ubuntu_major ?= 24
ubuntu_minor ?= 04

# Vault password file (optional)
vault_pass_file ?=

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
test:
	scripts/test_all_roles.sh
run_local:
	ansible-playbook playbooks/after_format.yaml --ask-vault-pass --ask-become-pass
test:
	$(if $(vault_pass_file),ANSIBLE_VAULT_PASSWORD_FILE=$(vault_pass_file),) UBUNTU_MAJOR=$(ubuntu_major) UBUNTU_MINOR=$(ubuntu_minor) scripts/test_all_roles.sh
clean-test-cache:
	@echo "🧹 Cleaning test cache..."
	@rm -f .molecule_test_cache
	@echo "✅ Test cache cleared"
