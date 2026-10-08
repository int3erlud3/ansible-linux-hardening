GITLEAKS_IMAGE := ghcr.io/gitleaks/gitleaks:v8.30.1

.PHONY: all deps lint syntax molecule scan
all: lint syntax

deps:
	pip install -r requirements-dev.txt
	ansible-galaxy collection install -r requirements.yml

lint:
	yamllint --strict .
	ansible-lint

syntax:
	ansible-playbook -i localhost, playbooks/site.yml --syntax-check

molecule:
	molecule test

scan:
	docker run --rm -v "$(CURDIR):/repo:ro" $(GITLEAKS_IMAGE) git /repo --redact --no-banner
