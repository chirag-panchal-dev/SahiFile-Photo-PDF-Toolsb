# SahiFile Google Play Release Checklist

### Pre-Launch Configuration
- [ ] **Application ID**: Confirm unique package identifier in `android/app/build.gradle.kts` (e.g. `com.sahifile.app`).
- [ ] **App Label**: Verified `SahiFile` in `AndroidManifest.xml`.
- [ ] **Icons**: Generate adaptive app icons and mipmap resources for all densities.
- [ ] **Version Code & Name**: Increment `versionCode` and `versionName` in `pubspec.yaml` and `build.gradle.kts`.

### Android Build & Signing
- [ ] **Keystore Setup**: Generate release upload keystore (`key.jks`) using `keytool`.
- [ ] **key.properties**: Configure `keyAlias`, `keyPassword`, `storePassword`, and `storeFile` locally outside version control.
- [ ] **ProGuard & R8**: Verify code shrinking rules in `android/app/proguard-rules.pro`.
- [ ] **Build Command**:
  ```bash
  flutter build appbundle --release
  ```

### Google Play Console Setup
- [ ] **App Title**: `SahiFile: Photo & PDF Tools` (under 30 characters).
- [ ] **Short Description**: `Resize photos, compress to exact KB, format signatures, and convert to PDF.` (under 80 characters).
- [ ] **Full Description**: Detail key workflows: exact KB target compression, background flattening for transparent signatures, Images to PDF, and on-device PDF merge.
- [ ] **Privacy Policy URL**: Host `docs/privacy-policy.md` on an accessible HTTPS URL.
- [ ] **Data Safety Form**: Declare that file processing runs locally on-device and that no files or personal data are collected or shared.
- [ ] **Permissions Review**: Verify that no broad storage permissions (`MANAGE_EXTERNAL_STORAGE` or `READ_EXTERNAL_STORAGE`) are requested.
