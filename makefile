.PHONY: run


image ?= ansible

run:
	scripts/run_container.sh $(image)
install:
	scripts/install_docker.sh
