.PHONY: deps format format-check lint test build clean check

# Default target - run all CI checks
check: format-check lint test
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

# Run tests
test:
	flutter test

# Build debug APK
build:
	flutter build apk --debug

# Clean build artifacts
clean:
	flutter clean
