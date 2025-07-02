# Score Card

AFL goal umpires app for keeping track of game scores.

## Features

- **Score Tracking**: Track goals, behinds, and total points for multiple teams
- **Quarter Management**: Organize scoring by quarters with running totals
- **Game History**: Save and review past games
- **Team Management**: Create and manage team information
- **Material Design**: Modern UI following Material 3 design principles

## Development

### Requirements

- Flutter 3.0 or higher
- Dart 3.0 or higher
- Android Studio / VS Code with Flutter extensions

### Setup

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the development server

### Building

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build appbundle --release
```

## Release Management

### Versioning Strategy

- **Semantic Versioning**: `MAJOR.MINOR.PATCH` (e.g., `1.2.3`)
- **Version Code**: Automatically calculated from semantic version
  - Formula: `MAJOR * 10000 + MINOR * 100 + PATCH`
  - Example: `1.2.3` → Version Code `10203`

### Creating a Release

#### Method 1: GitHub UI (Recommended)
1. Go to your GitHub repository
2. Click "Releases" → "Create a new release"
3. Click "Choose a tag" → Type new tag (e.g., `v1.2.3`)
4. Set release title: `Release 1.2.3`
5. Add release notes describing changes
6. Click "Publish release"

#### Method 2: Command Line
```bash
# Create and push a new tag
git tag v1.2.3
git push origin v1.2.3

# Then create release on GitHub UI or use GitHub CLI
gh release create v1.2.3 --title "Release 1.2.3" --notes "Bug fixes and improvements"
```

### Automated Release Process

When you create a release tag, the CI/CD pipeline automatically:
1. ✅ **Triggers CI/CD pipeline**
2. ✅ **Extracts version from tag** (`v1.2.3` → `1.2.3`)
3. ✅ **Calculates version code** (`1.2.3` → `10203`)
4. ✅ **Builds AAB with correct version**
5. ✅ **Creates GitHub release** with AAB attached
6. ✅ **Uploads to Play Store Internal Testing**
7. ✅ **Stores build artifact** for 30 days

## Deployment

### Required GitHub Secrets

#### Android Signing Secrets

```bash
# Generate a new keystore (run this locally)
keytool -genkey -v -keystore app-signing-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Convert keystore to base64 for GitHub secrets
base64 -i app-signing-keystore.jks | tr -d '\n' | pbcopy
```

Set these secrets in GitHub:
- `ANDROID_KEYSTORE`: Base64 encoded keystore file
- `KEYSTORE_PASSWORD`: Password you set for the keystore
- `KEY_ALIAS`: Key alias (e.g., "upload")
- `KEY_PASSWORD`: Password you set for the key

#### Google Play Console Secrets

1. **Enable Google Play Android Developer API**:
   - Go to https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com
   - Click "Enable"

2. **Create Service Account**:
   - Navigate to https://console.cloud.google.com/iam-admin/serviceaccounts
   - Click "Create Service Account"
   - Give it a name (e.g., "github-play-deploy")

3. **Generate Service Account Key**:
   - Click on the service account → "Keys" tab
   - Click "Add Key" → "Create new key" → Choose "JSON"
   - Save the downloaded file

4. **Add Service Account to Play Console**:
   - Go to https://play.google.com/console
   - Go to "Users and permissions" → "Invite new users"
   - Add the service account email with "Release to testing tracks" permission

5. **Set GitHub Secret**:
   - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`: Contents of the JSON key file

## Architecture

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── providers/                # State management (Provider pattern)
├── screens/                  # Main app screens
├── services/                 # Business logic and external services
└── widgets/                  # Reusable UI components
    ├── game_setup/          # Game setup related widgets
    └── scoring/             # Scoring interface widgets
```

### Key Services

- **GameRecordBuilder**: Handles game state and score calculations
- **GameHistoryService**: Manages saving and loading game history
- **NavigationService**: Handles app-wide navigation

## License

This project is licensed under the MIT License - see the LICENSE file for details.
