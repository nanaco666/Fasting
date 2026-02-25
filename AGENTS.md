# AGENTS.md

## Project Overview

**Fasting** is a native iOS intermittent fasting tracker app built entirely with Swift/SwiftUI. It uses zero third-party dependencies — only Apple-native frameworks (SwiftUI, SwiftData, Swift Charts, CloudKit, Observation).

See `README.md` for product details and `docs/ARCHITECTURE.md` for the MVVM + Clean Architecture structure.

## Cursor Cloud specific instructions

### Platform Constraint

This is a **native iOS app** — the full Xcode project (`Fasting/Fasting.xcodeproj`) **cannot be built on the Linux Cloud VM**. SwiftUI, SwiftData, and other Apple-only frameworks are not available on Linux. For full build, run, and UI testing, a macOS machine with Xcode 16+ is required (see `docs/SETUP.md`).

### What CAN run on the Cloud VM

The VM has **Swift 6.0.3** installed at `/opt/swift/usr/bin` (added to `PATH` via `~/.bashrc`) and **SwiftLint 0.63.2** at `/usr/local/bin/swiftlint`.

A cross-platform **Swift Package** (`Package.swift` at repo root) extracts the pure business logic into `FastingCore`:
- `Sources/FastingCore/` — platform-independent enums and utilities (`FastingPreset`, `FastingStatus`, `DurationFormatter`, `AppLanguage`)
- `Tests/FastingCoreTests/` — 20 unit tests covering presets, status codes, duration formatting, and language settings

### Common Commands

| Task | Command | Notes |
|------|---------|-------|
| **Lint** | `swiftlint lint` (from `Fasting/Fasting/`) | Checks all 12 app source files |
| **Build (SPM)** | `swift build` (from repo root) | Builds `FastingCore` library on Linux |
| **Test (SPM)** | `swift test` (from repo root) | Runs 20 cross-platform unit tests |

### Gotchas

- The `PATH` must include `/opt/swift/usr/bin` for `swift` commands. This is set in `~/.bashrc` but may need `export PATH="/opt/swift/usr/bin:$PATH"` in scripts.
- SwiftLint exit code is `2` when violations are found (not a build failure). The codebase currently has ~417 lint warnings and 5 errors (mostly trailing whitespace and short identifier names in `Theme.swift`).
- The SPM package (`Package.swift`) is a **development-only** cross-platform subset. The actual iOS app is built via `Fasting.xcodeproj` in Xcode.
- Test files under `Fasting/FastingTests/` and `Fasting/FastingUITests/` are Xcode-only (they use `import Testing` with Xcode's test runner and depend on SwiftData/SwiftUI). Only `Tests/FastingCoreTests/` runs on Linux.
