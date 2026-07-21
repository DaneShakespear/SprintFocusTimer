# Releasing SprintFocusTimer

Use this checklist when publishing a new GitHub Release.

## 1. Confirm The App Builds

```bash
xcodebuild \
  -project SprintFocusTimer.xcodeproj \
  -scheme SprintFocusTimer \
  -configuration Release \
  -destination 'platform=macOS' \
  MARKETING_VERSION=1.1.0 \
  CURRENT_PROJECT_VERSION=2 \
  build
```

## 2. Create The DMG

Preferred path:

1. Push the release-prep commit to GitHub.
2. Open the `Release` workflow in GitHub Actions.
3. Run the workflow with the version and build number.

The workflow builds the DMG on GitHub's macOS runner and creates or updates the GitHub Release.

Local fallback:

```bash
./scripts/create_dmg.sh
```

The DMG is created at:

```text
dist/SprintFocusTimer-1.1.0.dmg
```

## 3. Create A GitHub Release

1. Go to the repo on GitHub.
2. Open `Releases`.
3. Click `Draft a new release`.
4. Create a new version tag, such as `v1.1.0`.
5. Attach `dist/SprintFocusTimer-1.1.0.dmg`.
6. Mention that the app is unsigned and may require right-click > Open on first launch.

## Suggested Release Text

```text
SprintFocusTimer for macOS

Download SprintFocusTimer-1.1.0.dmg, open it, and drag SprintFocusTimer.app into Applications.

This build is unsigned and unnotarized. If macOS blocks it on first launch, right-click the app and choose Open. The source code is available in this repository for review.
```
