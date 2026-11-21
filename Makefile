.PHONY: check-builds publish publish-dry

check-builds:
	./scripts/check-builds.sh

publish:
	./scripts/trigger-publish.sh

publish-dry:
	./scripts/trigger-publish.sh --dry-run
