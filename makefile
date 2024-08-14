.PHONY: run


image ?= ansible

run:
	./scripts/container.sh $(image)
