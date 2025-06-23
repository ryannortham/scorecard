# GitHub Actions Setup Guide

This document explains how to set up the required GitHub secrets for the CI/CD pipeline to build and deploy your app to the Google Play Store.

## Required GitHub Secrets

You need to set up the following secrets in your GitHub repository:

### 1. Android Signing Secrets

First, you'll need to create an Android keystore for signing your release builds:

```bash
# Generate a new keystore (run this locally)
keytool -genkey -v -keystore app-signing-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Convert keystore to base64 for GitHub secrets
base64 -i app-signing-keystore.jks | tr -d '\n' | pbcopy
```

Set these secrets in GitHub:
- `ANDROID_KEYSTORE`: Base64 encoded keystore file (output from above command)
- `KEYSTORE_PASSWORD`: Password you set for the keystore
- `KEY_ALIAS`: Key alias (e.g., "upload")
- `KEY_PASSWORD`: Password you set for the key

### 2. Google Play Console Secrets

1. **Enable Google Play Android Developer API**:
   - Go to https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com
   - Click "Enable"

2. **Create Service Account**:
   - Navigate to https://console.cloud.google.com/iam-admin/serviceaccounts
   - Click "Create Service Account"
   - Give it a name (e.g., "github-play-deploy")
   - Don't grant any permissions yet
   - Click "Done"

3. **Generate Service Account Key**:
   - Click on the service account you just created
   - Go to "Keys" tab
   - Click "Add Key" → "Create new key"
   - Choose "JSON" format
   - Save the downloaded file

4. **Add Service Account to Play Console**:
   - Go to https://play.google.com/console
   - Go to "Users and permissions"
   - Click "Invite new users"
   - Add the service account email
   - Grant permissions for the app you want to deploy

Set these secrets in GitHub:
- `SERVICE_ACCOUNT_JSON`: The entire content of the JSON file downloaded in step 3
- `PACKAGE_NAME`: Your app's package name (`blog.ryannortham.scorecard`)

## Setting GitHub Secrets

1. Go to your GitHub repository
2. Click "Settings" → "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Add each secret with the exact names listed above

## Important Notes

- **First Upload**: You must manually upload your app to the Play Console at least once before using the GitHub Action
- **Package Name**: Make sure the package name in the secret matches your `android/app/build.gradle` file
- **Track Configuration**: The workflow is set to deploy to "production" track. You can change this to "internal", "alpha", or "beta" in the workflow file if needed
- **Release Notes**: Update the files in `android/whatsnew/` directory to provide release notes for your app updates

## Testing the Workflow

1. Make sure all secrets are set up correctly
2. Push to the main branch
3. Check the Actions tab in your GitHub repository to monitor the workflow
4. The workflow will:
   - Run tests and code analysis
   - Build a release AAB
   - Upload it as an artifact
   - Deploy to Google Play Store

## Troubleshooting

- If you get "Package not found" error, make sure you've manually uploaded your app to Play Console first
- If signing fails, double-check your keystore secrets
- If Play Store upload fails, verify your service account has the correct permissions

## Security Notes

- Never commit keystore files or service account JSON to your repository
- Use strong passwords for your keystore
- Regularly rotate your service account keys
- Consider using workload identity federation for additional security (see the upload-google-play action documentation)
