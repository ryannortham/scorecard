# Release Management Guide

This guide explains how to manage versions and releases for your Flutter app using the automated CI/CD pipeline.

## 🏷️ **Versioning Strategy**

### **Version Format**
- **Semantic Versioning**: `MAJOR.MINOR.PATCH` (e.g., `1.2.3`)
- **Version Code**: Automatically calculated from semantic version
  - Formula: `MAJOR * 10000 + MINOR * 100 + PATCH`
  - Example: `1.2.3` → Version Code `10203`

### **Build Types**
1. **Release Builds** (from Git tags): `1.2.3`
2. **Development Builds** (from main branch): `dev-abc12345`

## 🚀 **How to Create a Release**

### **Method 1: GitHub UI (Recommended)**
1. Go to your GitHub repository
2. Click "Releases" → "Create a new release"
3. Click "Choose a tag" → Type new tag (e.g., `v1.2.3`)
4. Set release title: `Release 1.2.3`
5. Add release notes describing changes
6. Click "Publish release"

### **Method 2: Command Line**
```bash
# Create and push a new tag
git tag v1.2.3
git push origin v1.2.3

# Then create release on GitHub UI or use GitHub CLI
gh release create v1.2.3 --title "Release 1.2.3" --notes "Bug fixes and improvements"
```

## 🔄 **What Happens When You Release**

### **Automatic Actions:**
1. ✅ **Triggers CI/CD pipeline**
2. ✅ **Extracts version from tag** (`v1.2.3` → `1.2.3`)
3. ✅ **Calculates version code** (`1.2.3` → `10203`)
4. ✅ **Builds AAB with correct version**
5. ✅ **Creates GitHub release** with AAB attached
6. ✅ **Uploads to Play Store Internal Testing**
7. ✅ **Stores build artifact** for 30 days

### **Generated Artifacts:**
- GitHub release with AAB download
- Play Store internal testing build
- Build artifacts in GitHub Actions

## 📱 **Version Progression Examples**

```
v1.0.0 → First release
v1.0.1 → Bug fix (patch)
v1.1.0 → New feature (minor)
v2.0.0 → Breaking changes (major)
```

## 🎯 **Release Tracks Strategy**

### **Current Setup:**
- **All builds** → `internal` track (safe testing)

### **Recommended Progression:**
1. **Internal testing** → Validate with team
2. **Promote to Alpha** → Closed testing group
3. **Promote to Beta** → Open testing
4. **Promote to Production** → Public release

### **Updating Tracks:**
To change the default track, edit `.github/workflows/flutter.yml`:
```yaml
# For production releases
TRACK="production"

# For beta testing
TRACK="beta"
```

## 📝 **Release Notes Management**

### **Update Release Notes:**
1. Edit `android/whatsnew/whatsnew-en-US`
2. Add more languages: `whatsnew-es-ES`, `whatsnew-fr-FR`, etc.
3. Commit changes before creating release

### **Example Release Notes:**
```
🎉 New Features:
- Added dark mode support
- Improved score tracking

🐛 Bug Fixes:
- Fixed crash on game reset
- Improved performance

🔧 Improvements:
- Updated UI design
- Better error handling
```

## 🔧 **Advanced Workflows**

### **Hotfix Releases:**
```bash
# Create hotfix branch
git checkout -b hotfix/1.2.1 v1.2.0
# Make fixes
git commit -m "Fix critical bug"
# Tag and release
git tag v1.2.1
git push origin v1.2.1
```

### **Pre-release Testing:**
```bash
# Create pre-release tag
git tag v1.3.0-beta.1
git push origin v1.3.0-beta.1
# Create pre-release on GitHub
gh release create v1.3.0-beta.1 --prerelease
```

### **Emergency Rollback:**
1. Go to Play Console
2. Find previous version in releases
3. Click "Promote to production"
4. Or use the rollback feature

## 🛡️ **Best Practices**

### **Before Releasing:**
- ✅ Test thoroughly on internal track
- ✅ Update release notes
- ✅ Verify version number is correct
- ✅ Check all features work as expected

### **Version Bumping:**
- **Patch** (`1.0.1`): Bug fixes only
- **Minor** (`1.1.0`): New features, backwards compatible
- **Major** (`2.0.0`): Breaking changes

### **Release Frequency:**
- **Internal builds**: Every main branch push
- **Releases**: Weekly/bi-weekly for features
- **Hotfixes**: As needed for critical bugs

## 🚨 **Troubleshooting**

### **Common Issues:**
- **Duplicate version code**: Increment patch version
- **Build fails**: Check GitHub Actions logs
- **Play Store rejects**: Ensure version code is higher than previous

### **Monitoring:**
- GitHub Actions for build status
- Play Console for deployment status
- Internal testing feedback for quality

## 📊 **Monitoring Releases**

### **Track Success:**
1. **GitHub Actions**: Build and deployment status
2. **Play Console**: Download/install metrics
3. **Crash reporting**: Monitor stability
4. **User feedback**: Internal tester reports

This setup gives you professional-grade release management with minimal manual work! 🎉
