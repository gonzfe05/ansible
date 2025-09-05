.PHONY: run


image ?= ubuntu:22.04

run:
	scripts/run_container.sh $(image)
install:
	scripts/install_docker.sh
	sudo scripts/install_ansible.sh
run_local:
	ansible-playbook playbooks/after_format.yaml --ask-vault-pass --ask-become-pass

test:
	./scripts/test_all_roles.sh

test-role:
	@if [ -z "$(ROLE)" ]; then echo "Usage: make test-role ROLE=<role_name>"; exit 1; fi
	cd playbooks/roles/$(ROLE) && molecule test
