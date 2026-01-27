# Releasing

Guide for releasing Scorecard to Google Play Store.

## Overview

Scorecard uses a simple continuous delivery workflow:

- **Source of truth**: `pubspec.yaml` for version name, Play Console for build promotion
- **Automatic**: Every push to `main` builds and uploads to Play Store as a draft
- **Manual**: Promotion through testing tracks is done in Play Console

## Versioning

| Component | Source | Example |
|-----------|--------|---------|
| Version name | `pubspec.yaml` | `1.0.0` |
| Version code | CI build number | `294`, `295`, etc. |

The version code auto-increments with each CI build. You never need to manage it manually.

### Bumping Version

Update `pubspec.yaml` when starting a new version cycle:

```yaml
# Before
version: 1.0.0

# After
version: 1.1.0
```

All subsequent builds will use the new version name.

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

## Fastlane Metadata

Play Store listing metadata is stored in `android/fastlane/metadata/android/en-US/`:

```text
android/fastlane/metadata/android/en-US/
├── title.txt                 # App name (30 chars max)
├── short_description.txt     # Short description (80 chars max)
├── full_description.txt      # Full description (4000 chars max)
└── images/
    └── phoneScreenshots/     # Screenshots (2-8 required)
```

To update Play Store listing:

1. Edit the metadata files locally
2. Use `fastlane supply` to sync, or
3. Edit directly in Play Console

## Git Tags (Optional)

For tracking purposes, you can tag releases after promoting to production:

```bash
git tag v1.0.0
git push origin v1.0.0
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
