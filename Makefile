SUPER_LINTER_VERSION := $(shell grep -e '- uses: super-linter/super-linter@' .github/workflows/ci.yaml | cut -d'@' -f2)

lint:
	docker run --rm --platform=linux/amd64 \
		-e RUN_LOCAL=true \
		-e SHELL=/bin/bash \
		--env-file ".github/super-linter.env" \
		-v "$$PWD":/tmp/lint \
		ghcr.io/super-linter/super-linter:$(SUPER_LINTER_VERSION)

fix:
	docker run --rm --platform=linux/amd64 \
		-e FIX=true \
		-e RUN_LOCAL=true \
		-e SHELL=/bin/bash \
		--env-file ".github/super-linter.env" \
		-v "$$PWD":/tmp/lint \
		ghcr.io/super-linter/super-linter:$(SUPER_LINTER_VERSION)
