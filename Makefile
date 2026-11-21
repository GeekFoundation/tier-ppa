.PHONY: check-build publish publish-dry

check-build:
	./scripts/check-build.sh

publish:
	./scripts/trigger-publish.sh

publish-dry:
	./scripts/trigger-publish.sh --dry-run
