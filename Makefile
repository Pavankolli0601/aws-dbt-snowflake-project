# dbt + SQLFluff convenience targets. Run from project root.
# Prereqs: env vars set (see README), profiles.yml from profiles.yml.example

.PHONY: deps build test lint run snapshot docs help

# Default: show targets
help:
	@echo "Targets:"
	@echo "  make deps   - dbt deps"
	@echo "  make build  - dbt build (run + test)"
	@echo "  make test  - dbt test"
	@echo "  make lint  - sqlfluff lint"
	@echo "  make run   - dbt run"
	@echo "  make snapshot - dbt snapshot"
	@echo "  make docs  - dbt docs generate"
	@echo "  make all   - deps + build + lint"

deps:
	dbt deps

build:
	dbt build

test:
	dbt test

lint:
	sqlfluff lint models/ snapshots/ macros/

run:
	dbt run

snapshot:
	dbt snapshot

docs:
	dbt docs generate

# One-liner: install deps, build, and lint (no DB needed for lint if deps only)
all: deps build lint
