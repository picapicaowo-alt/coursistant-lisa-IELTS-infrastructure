SHELL := /bin/bash

.PHONY: fmt validate lint check

fmt:
	terraform fmt -recursive

validate:
	./scripts/validate.sh

lint:
	tflint --recursive
	shellcheck scripts/*.sh

check: fmt validate lint
