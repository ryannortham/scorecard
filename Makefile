.PHONY: deps format format-check lint lint-fix lint-md lint-md-fix test build clean check

# Default target - run all CI checks
check: format-check lint lint-md test
	@echo "✓ All checks passed"

# Install dependencies
deps:
	flutter pub get

# Format code (auto-fix)
format:
	dart format .

# Verify formatting (strict, matches CI)
format-check:
	dart format --output=none --set-exit-if-changed .

# Run static analysis
lint:
	flutter analyze

# Auto-fix lint issues where possible
lint-fix:
	dart fix --apply

# Lint markdown files (matches CI: includes dotfiles, recursive glob)
lint-md:
	markdownlint --dot "**/*.md"

# Auto-fix markdown lint issues
lint-md-fix:
	markdownlint --dot --fix "**/*.md"

# Run tests
test:
	flutter test

# Build debug APK
build:
	flutter build apk --debug

# Clean build artifacts
clean:
	flutter clean

# Run performance benchmark tests
benchmark:
	@echo "Running performance benchmarks..."
	flutter test test/benchmark/ --reporter expanded
	@echo ""
	@echo "Results written to build/benchmark_results.json"

# View benchmark results
benchmark-report:
	@echo ""
	@if [ -f "build/benchmark_results.json" ]; then \
		cat build/benchmark_results.json; \
	else \
		echo "No results found. Run 'make benchmark' first."; \
	fi
	@echo ""
