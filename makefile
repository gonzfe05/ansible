.PHONY: run


image ?= ubuntu:22.04

run:
	scripts/run_container.sh $(image)
install:
	scripts/install_docker.sh
	scripts/install_ansible.sh
run_local:
	ansible-playbook playbooks/after_format.yaml --ask-vault-pass --ask-become-pass
