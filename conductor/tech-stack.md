# Technology Stack

## Core Framework & Language
- **Language:** [Dart](https://dart.dev/) (SDK: >=3.7.0 <4.0.0) - A client-optimized language for fast apps on any platform.
- **Framework:** [Flutter](https://flutter.dev/) - Google's UI toolkit for building beautiful, natively compiled applications for mobile, web, and desktop from a single codebase.

## State Management & Architecture
- **State Management:** [Provider](https://pub.dev/packages/provider) - A wrapper around InheritedWidget to make them easier to use and more reusable.
- **Architecture Pattern:** MVVM (Model-View-ViewModel) - Separating the UI (View) from the logic (ViewModel) and data (Model) for better maintainability and testability.

## Navigation
- **Router:** [go_router](https://pub.dev/packages/go_router) - A declarative routing package for Flutter that uses the Router API to provide a convenient, url-based API for navigation.

## Data & Storage
- **Local Storage:** [shared_preferences](https://pub.dev/packages/shared_preferences) - Wraps platform-specific persistent storage for simple data (NSUserDefaults on iOS and macOS, SharedPreferences on Android, etc.).
- **External Integration:** PlayHQ GraphQL API - Integrated for fetching real-time team and match data.

## UI & Design
- **Design System:** [Material Design 3](https://m3.material.io/) - The latest version of Google’s open-source design system.
- **Key UI Libraries:**
    - `cached_network_image`: For efficient image loading and caching.
    - `confetti`: For celebration effects.
    - `dynamic_color`: For supporting Material You're dynamic color schemes.

## Quality & Tooling
- **Linting:** `very_good_analysis` - Comprehensive lint rules to ensure code quality and consistency.
- **Testing:** `flutter_test` - For unit and widget testing.
- **CI/CD:** GitHub Actions - Automating the build, test, and release pipeline.
