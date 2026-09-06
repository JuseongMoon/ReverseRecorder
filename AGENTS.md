# Repository Guidelines

## Project Structure & Module Organization
All Swift sources live under `ReverseRecorder/`. Scene entry points (`ReverseRecorderApp.swift`, `ContentView.swift`) sit at the root, domain files stay under `Models/`, `Services/`, and `ViewModels/RecorderViewModel.swift`, and reusable SwiftUI elements live in `Views/`. Assets belong in `Assets.xcassets`. Mirror this layout when adding features so each module stays single-purpose.

## Build, Test, and Development Commands
Develop in Xcode: open `ReverseRecorder.xcodeproj`, select the `ReverseRecorder` scheme, and run on an iOS 18.6+ simulator (the app target's deployment target is 18.6). Run `xcodebuild -project ReverseRecorder.xcodeproj -scheme ReverseRecorder -destination 'platform=iOS Simulator,name=iPhone 16' build` before each push; there is no test target yet, so `xcodebuild test` will fail.

## Coding Style & Naming Conventions
Follow Swift API Design Guidelines: PascalCase types, camelCase members, and one primary type per file. Indent with four spaces, keep braces on the same line, and use explicit access control. Add `// MARK:` blocks to split state, lifecycle, and helpers, and hide AVFoundation details behind small service protocols for testability.

## Testing Guidelines
There is no test target in this project yet. If you add one, create `ReverseRecorderTests/` alongside the app target with XCTest, mirror the source directories (`ServicesTests`, `ViewModelsTests`), name methods `test<Action>_<Condition>_<Result>()`, and start with audio permission flows, waveform reversal, and toast timing. Until then, verify changes by building and exercising the recorder manually in the simulator, and attach simulator logs for audio issues.

## Commit & Pull Request Guidelines
Commits should use short, action-driven subjects that say what changed. Group related changes per commit and squash noisy WIP. PRs must include user-facing impact, verification evidence (command output or simulator screenshots), known limitations, and links to tracked issues. Add demo recordings or GIFs when UI behavior changes.

## Security & Configuration Tips
Keep `NSMicrophoneUsageDescription` accurate whenever behavior changes. Never commit real recordings; rely on placeholder `.m4a` assets for demos. Exclude derived data and signing material from git, and move any future secrets into `.xcconfig` files.
