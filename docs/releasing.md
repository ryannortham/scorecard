# Releasing

Guide for releasing Scorecard to Google Play Store and Apple App Store.

## Overview

Scorecard uses Fastlane for release automation with a continuous delivery workflow:

- **Source of truth**: `pubspec.yaml` for version name, Play Console for build promotion
- **Automatic**: Every push to `main` builds and uploads to Play Store as a draft
- **Manual**: Promotion through testing tracks is done in Play Console
- **Shared metadata**: All metadata files are stored in `metadata/en-AU/`, synced to platform-specific directories during CI
- **Screenshots**: Stored in `metadata/screenshots/`, synced to Fastlane automatically during CI deploy

## Versioning

Version names follow the format `MAJOR.MINOR.PATCH` where:

- **MAJOR.MINOR** comes from `pubspec.yaml` (the trailing `.0` is stripped)
- **PATCH** is the CI build number plus offset (auto-incremented)

| Component | Source | Example (run #97) |
|-----------|--------|-------------------|
| Version name | `{major}.{minor}.{200 + run_number}` | `1.0.297` |
| Version code | `200 + run_number` | `297` |
| Release name | Same as version name | `1.0.297` |

The offset of 200 ensures version codes continue above historical releases (max was 293).

### Bumping Version

Update `pubspec.yaml` when starting a new minor or major version:

```yaml
# Before
version: 1.0.0

# After (minor bump)
version: 1.1.0

# Or (major bump)
version: 2.0.0
```

Subsequent builds will be `1.1.297`, `1.1.298`, etc. (or `2.0.297`, `2.0.298`, etc.).

> **Note:** Flutter requires three-part version numbers in pubspec.yaml. The CI pipeline
> strips the trailing `.0` when constructing the version name.

## Workflow

### Development

1. Push changes to `main`
2. CI runs tests, builds AAB, uploads to Play Store as draft
3. Build appears in Play Console under **Internal testing** as a draft

### Testing

1. Open [Play Console](https://play.google.com/console)
2. Navigate to **Release** > **Testing** > **Internal testing**
3. Find the draft release you want to test
4. Click **Edit release** > **Review release** > **Start rollout to Internal testing**
5. Internal testers receive the update

### Promoting to Production

1. In Play Console, select the tested build
2. Click **Promote release** and choose the target track:
   - **Closed testing** - Invite-only beta
   - **Open testing** - Public beta (anyone can join)
   - **Production** - Public release
3. Add release notes (What's New)
4. Review and confirm rollout

The same build binary flows through all tracks - no rebuilding required.

### Staged Rollouts

For production releases, consider staged rollouts:

1. Start with 10% of users
2. Monitor crash reports and reviews
3. Gradually increase to 50%, then 100%

This limits impact if issues are discovered.

## Play Store Tracks

| Track | Purpose | Audience |
|-------|---------|----------|
| Internal testing | Early builds for core team | Up to 100 invited testers |
| Closed testing | Beta testing | Invite-only groups |
| Open testing | Public beta | Anyone can opt-in |
| Production | Public release | All users |

## CI/CD Pipeline

### Triggers

| Event | Test | Build | Deploy |
|-------|------|-------|--------|
| Push to any branch | ✓ | ✓ | ✗ |
| Pull request | ✓ | ✓ | ✗ |
| Push to main | ✓ | ✓ | ✓ |
| Weekly schedule | ✓ | ✗ | ✗ |

### Build Outputs

- **AAB artifact**: Available in GitHub Actions for 30 days
- **Play Store draft**: Available in Play Console for promotion

## Release Notes

Release notes (What's New) are managed in the shared metadata directory and automatically
synced to platform-specific directories during CI deployment.

### Release Notes Location

```text
metadata/en-AU/release_notes.txt
```

This is the single source of truth for all platforms. During CI deployment, this file is
synced to `android/fastlane/metadata/android/en-AU/changelogs/default.txt` for the Play Store.

### Editing Release Notes

```bash
# Edit in vim
make release-notes

# View current notes
make release-notes-show
```

### Example Content

```text
New in this update:

• Score Worm graph - see how the game unfolded at a glance
• Google Maps built in - get directions to away games easily
• Smoother navigation and polished animations
```

Keep release notes concise and user-friendly (max 500 characters). Focus on benefits, not
technical details.

## Screenshots

Screenshots are stored in the shared metadata directory and automatically synced to Fastlane
during CI deployment. No local copies are stored in the Fastlane metadata directories.

### Screenshots Location

```text
metadata/screenshots/
├── 1_setup.png         # Game setup screen
├── 2_scoring.png       # Live scoring screen
├── 3_results.png       # Game results screen
└── 4_team_details.png  # Team details screen
```

### Ordering

**Fastlane orders screenshots alphabetically by filename.** Use numeric prefixes to control
the display order on the Play Store:

| Filename | Display Order |
|----------|---------------|
| `1_setup.png` | 1st |
| `2_scoring.png` | 2nd |
| `3_results.png` | 3rd |
| `4_team_details.png` | 4th |

### Updating Screenshots

1. Replace or add files in `metadata/screenshots/`
2. Use numeric prefix to set display order (e.g., `5_new_feature.png`)
3. Push to `main` - CI will sync screenshots to `android/fastlane/metadata/` and upload with the next deploy

## Metadata Management

All app store metadata is stored in a shared directory at the project root and synced to
platform-specific directories during CI deployment.

### Shared Metadata Directory

```text
metadata/
├── en-AU/                        # Australian English (primary locale)
│   ├── title.txt                 # App name (30 chars max)
│   ├── short_description.txt     # Short description (80 chars max) - Android only
│   ├── subtitle.txt              # Subtitle (30 chars max) - iOS only
│   ├── description.txt           # Full description (4000 chars max)
│   ├── release_notes.txt         # Release notes (What's New)
│   └── keywords.txt              # Keywords - iOS only
└── screenshots/
    ├── 1_setup.png               # Game setup screen
    ├── 2_scoring.png             # Live scoring screen
    ├── 3_results.png             # Game results screen
    └── 4_team_details.png        # Team details screen
```

### CI Metadata Sync Process

During the deploy step, the CI pipeline syncs metadata from the shared directory to
platform-specific Fastlane directories:

```bash
# Android
cp metadata/en-AU/title.txt → android/fastlane/metadata/android/en-AU/title.txt
cp metadata/en-AU/short_description.txt → android/fastlane/metadata/android/en-AU/short_description.txt
cp metadata/en-AU/description.txt → android/fastlane/metadata/android/en-AU/full_description.txt
cp metadata/en-AU/release_notes.txt → android/fastlane/metadata/android/en-AU/changelogs/default.txt
cp metadata/screenshots/* → android/fastlane/metadata/android/en-AU/images/phoneScreenshots/
```

**Note**: The synced metadata files in `android/fastlane/` are ignored by Git (see
`android/.gitignore`). They are rebuilt on every deploy to keep them in sync with the
source of truth in `metadata/`.

### Why Shared Metadata?

- **Single source of truth**: All metadata is edited in one location
- **Platform flexibility**: Same content can be adapted for different app stores (iOS, Google Play)
- **Clean repo**: Platform-specific directories only contain auto-generated files (ignored by Git)
- **Future-proof**: Easy to extend for iOS and other platforms

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make release-notes` | Edit release notes in vim |
| `make release-notes-show` | Display current release notes |

## iOS Releases (Future)

iOS Fastlane configuration is prepared but not yet active. The structure is in place at
`ios/fastlane/` with stub lanes that will error until an Apple Developer account is configured.

### When Ready

1. Create Apple Developer account
2. Update `ios/fastlane/Appfile` with Apple ID and team IDs
3. Set up code signing (manual or Fastlane `match`)
4. Uncomment the `beta` lane in `ios/fastlane/Fastfile`
5. Add App Store Connect API key to GitHub secrets

## Git Tags (Optional)

For tracking purposes, you can tag releases after promoting to production:

```bash
git tag v1.0.95
git push origin v1.0.95
```

This is optional and doesn't affect the CI/CD pipeline.

## Troubleshooting

### Build failed in CI

1. Check GitHub Actions logs for the specific error
2. Common issues:
   - Lint failures: Run `make lint` locally
   - Test failures: Run `make test` locally
   - Signing issues: Check GitHub secrets are configured

### Draft not appearing in Play Console

1. Check the deploy step completed successfully in GitHub Actions
2. Ensure `SERVICE_ACCOUNT_JSON` secret has correct permissions
3. Check Play Console API access is enabled

### Version code conflict

The version code uses `GITHUB_RUN_NUMBER` which always increases. If you see conflicts:

1. Check if a manual upload was done with a higher version code
2. The next CI build will have a higher number and succeed
