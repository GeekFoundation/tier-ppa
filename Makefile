.PHONY: check-builds publish publish-dry

REVISION ?= 1

check-builds:
	./scripts/check-builds.sh

publish:
	./scripts/trigger-publish.sh --revision=$(REVISION)

publish-dry:
	./scripts/trigger-publish.sh --dry-run --revision=$(REVISION)
