# Development Guide

This guide provides detailed information for developers working on Scorecard.

## Table of Contents

- [Requirements](#requirements)
- [Setup](#setup)
- [Development Workflow](#development-workflow)
- [Build Commands](#build-commands)
- [Testing](#testing)
- [Code Quality](#code-quality)
- [Troubleshooting](#troubleshooting)

## Requirements

### System Requirements

- **Operating System**: macOS, Linux, or Windows
- **Flutter SDK**: 3.35.3 or higher
- **Dart SDK**: 3.9.2 or higher (included with Flutter)
- **Java**: JDK 17 or higher (for Android builds)
- **Android Studio** or **VS Code** with Flutter extensions

### Flutter Installation

If you don't have Flutter installed:

```bash
# macOS (using Homebrew)
brew install flutter

# Or download from official website
# https://docs.flutter.dev/get-started/install
```

Verify your installation:

```bash
flutter doctor -v
```

### IDE Setup

#### VS Code (Recommended)

Install these extensions:

- [Flutter](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
- [Dart](https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code)

#### Android Studio

Install the Flutter and Dart plugins from:

- **Preferences** → **Plugins** → Search for "Flutter"

## Setup

### 1. Clone the Repository

```bash
git clone https://github.com/ryannortham/scorecard.git
cd scorecard
```

### 2. Install Dependencies

Using Make (recommended):

```bash
make deps
```

Or manually:

```bash
flutter pub get
```

### 3. Configure Environment

Create a `.env` file in the project root:

```bash
# Optional: Google Maps API key for team locations
GOOGLE_MAPS_API_KEY=your_api_key_here
```

> **Note:** The app will work without the API key, but team location features will be disabled.

### 4. Verify Setup

Run the app to ensure everything is working:

```bash
flutter run
```

Or use the IDE's run button.

## Development Workflow

### Branch Strategy

- `main` - Production-ready code
- `refactor` - Development branch (synced with main)
- `feature/*` - Feature branches
- `fix/*` - Bug fix branches

### Making Changes

1. **Create a feature branch:**

   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** and test locally

3. **Run quality checks:**

   ```bash
   make check  # Runs format-check, lint, and tests
   ```

4. **Commit your changes:**

   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

5. **Push and create a Pull Request:**

   ```bash
   git push origin feature/your-feature-name
   ```

### Commit Message Convention

Use conventional commit format:

- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code refactoring
- `docs:` - Documentation changes
- `test:` - Test additions/changes
- `chore:` - Build process or auxiliary tool changes
- `style:` - Code style changes (formatting)

## Build Commands

The project uses a `Makefile` for common tasks:

### Available Commands

```bash
# Install dependencies
make deps

# Format code
make format

# Check code formatting (without modifying files)
make format-check

# Run static analysis
make lint

# Attempt to auto-fix lint issues
make lint-fix

# Run all tests
make test

# Build debug APK
make build

# Clean build artifacts
make clean

# Run all CI checks (format-check + lint + test)
make check
```

### Manual Build Commands

If you prefer not to use Make:

```bash
# Install dependencies
flutter pub get

# Format code
dart format .

# Check formatting
dart format --output=none --set-exit-if-changed .

# Run static analysis
flutter analyze

# Run tests
flutter test

# Build debug APK
flutter build apk --debug

# Build release APK (requires signing configuration)
flutter build apk --release

# Build release App Bundle (for Play Store)
flutter build appbundle --release

# Clean build cache
flutter clean
```

## Testing

### Running Tests

```bash
# Run all tests
make test

# Or manually
flutter test

# Run specific test file
flutter test test/models/score_test.dart

# Run tests with coverage
flutter test --coverage
```

### Test Structure

```text
test/
├── viewmodels/          # ViewModel tests
├── services/            # Service tests
└── widgets/             # Widget tests (future)
```

### Writing Tests

Example test structure:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeatureName', () {
    test('should do something', () {
      // Arrange
      final input = 'test';
      
      // Act
      final result = doSomething(input);
      
      // Assert
      expect(result, equals('expected'));
    });
  });
}
```

## Code Quality

### Static Analysis

The project uses [very_good_analysis](https://pub.dev/packages/very_good_analysis) for comprehensive lint rules.

Configuration: `analysis_options.yaml`

```bash
# Run linter
make lint

# Attempt auto-fixes
make lint-fix
```

### Code Formatting

Uses Dart's standard formatter:

```bash
# Format all files
make format

# Check formatting without modifying
make format-check
```

### Pre-commit Checklist

Before committing, ensure:

- [ ] Code is formatted (`make format`)
- [ ] No lint issues (`make lint`)
- [ ] All tests pass (`make test`)
- [ ] New code has tests
- [ ] Documentation is updated

Or run everything at once:

```bash
make check
```

## Troubleshooting

### Common Issues

#### "Flutter SDK not found"

Ensure Flutter is in your PATH:

```bash
# Add to ~/.zshrc or ~/.bashrc
export PATH="$PATH:/path/to/flutter/bin"
```

#### "Pub get failed"

Clear the package cache:

```bash
flutter clean
flutter pub get
```

#### "Gradle build failed"

1. Ensure Java 17 is installed and in PATH
2. Clean the build:

   ```bash
   make clean
   flutter build apk --debug
   ```

#### "Android SDK not found"

Run Flutter doctor to diagnose:

```bash
flutter doctor -v
```

Follow the instructions to install missing components.

### Getting Help

If you encounter issues:

1. Check [Flutter documentation](https://docs.flutter.dev)
2. Search [existing issues](https://github.com/ryannortham/scorecard/issues)
3. Create a [new issue](https://github.com/ryannortham/scorecard/issues/new) with:
   - Steps to reproduce
   - Expected vs actual behavior
   - Output of `flutter doctor -v`
   - Relevant error messages

## Additional Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design 3](https://m3.material.io)
- [Provider Package](https://pub.dev/packages/provider)
- [Very Good Analysis](https://pub.dev/packages/very_good_analysis)
