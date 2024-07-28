.PHONY: run


image ?= ansible

run:
	./scripts/run_container.sh $(image)
