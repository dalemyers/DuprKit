.PHONY: build test clean format lint lint-fix format-check help

help:
	@echo "DuprKit Makefile Commands:"
	@echo ""
	@echo "  make build        - Build the package"
	@echo "  make test         - Run all tests"
	@echo "  make format       - Format code with SwiftFormat"
	@echo "  make format-check - Check if code is formatted (CI)"
	@echo "  make lint         - Run SwiftLint"
	@echo "  make lint-fix     - Run SwiftLint with auto-fix"
	@echo "  make clean        - Clean build artifacts"
	@echo "  make pre-commit   - Run format and lint (use before committing)"
	@echo ""

build: format lint
	swift build

test: format lint
	swift test

clean:
	swift package clean
	rm -rf .build

format:
	@echo "Running SwiftFormat..."
	@if command -v swiftformat >/dev/null 2>&1; then \
		swiftformat . ; \
	else \
		echo "Error: swiftformat not found. Install with: brew install swiftformat"; \
		exit 1; \
	fi

format-check:
	@echo "Checking code formatting..."
	@if command -v swiftformat >/dev/null 2>&1; then \
		swiftformat --lint . ; \
	else \
		echo "Error: swiftformat not found. Install with: brew install swiftformat"; \
		exit 1; \
	fi

lint:
	@echo "Running SwiftLint..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint ; \
	else \
		echo "Error: swiftlint not found. Install with: brew install swiftlint"; \
		exit 1; \
	fi

lint-fix:
	@echo "Running SwiftLint with auto-fix..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint --fix ; \
	else \
		echo "Error: swiftlint not found. Install with: brew install swiftlint"; \
		exit 1; \
	fi

pre-commit: format lint
	@echo "✓ Code is formatted and linted"
