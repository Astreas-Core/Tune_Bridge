# TuneBridge

TuneBridge is a Flutter music app focused on local library playback, playlist management, Spotify import/auth flows, and a rich now-playing experience.

## Requirements

- Flutter 3.41.4 (stable)
- Dart 3.11.1
- Android SDK configured for Flutter

## Run Locally

1. Install dependencies:

	flutter pub get

2. Run the app:

	flutter run

## Build Release Artifacts

Build APK:

flutter build apk --release

Output:

build/app/outputs/flutter-apk/app-release.apk

Build Android App Bundle (recommended for stores):

flutter build appbundle --release

Output:

build/app/outputs/bundle/release/app-release.aab

## Signing Notes

This repository ignores local Android signing files:

- android/key.properties
- android/local.properties

Create your own keystore and key.properties locally before publishing to an app store.

## Suggested GitHub Release Flow

1. Commit your changes.
2. Create a version tag (example: v1.0.0).
3. Push commits and tag to GitHub.
4. Create a GitHub Release from that tag.
5. Attach app-release.apk (and optionally app-release.aab) to the release.

## In-App Update Checker (GitHub Releases)

The Settings screen includes an Update section that checks your latest GitHub release and opens the APK download link.

Before using it, configure these constants in lib/core/constants.dart:

- githubOwner
- githubRepo

Then publish releases with semantic tags like v1.0.1 and include an APK asset in each release.

Behavior:

- The app compares installed version with latest release tag.
- If a newer version exists, users can tap Download Update.
- Android will prompt users to confirm APK installation (manual confirmation is required).

## Quality Checks

- flutter test
- flutter analyze

Note: The project currently has analyzer info-level hints in one file, but release builds and tests pass.
