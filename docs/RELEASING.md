# Releasing SprintFocusTimer

Use this checklist when publishing a new GitHub Release.

## 1. Confirm The App Builds

```bash
xcodebuild \
  -project SprintFocusTimer.xcodeproj \
  -scheme SprintFocusTimer \
  -configuration Release \
  -destination 'platform=macOS' \
  build
```

## 2. Create The DMG

```bash
./scripts/create_dmg.sh
```

The DMG is created at:

```text
dist/SprintFocusTimer.dmg
```

## 3. Create A GitHub Release

1. Go to the repo on GitHub.
2. Open `Releases`.
3. Click `Draft a new release`.
4. Create a new version tag, such as `v1.0.0`.
5. Attach `dist/SprintFocusTimer.dmg`.
6. Mention that the app is unsigned and may require right-click > Open on first launch.

## Suggested Release Text

```text
SprintFocusTimer for macOS

Download SprintFocusTimer.dmg, open it, and drag SprintFocusTimer.app into Applications.

This build is unsigned and unnotarized. If macOS blocks it on first launch, right-click the app and choose Open. The source code is available in this repository for review.
```
