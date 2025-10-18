.PHONY: run test


image ?= ubuntu:22.04

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
