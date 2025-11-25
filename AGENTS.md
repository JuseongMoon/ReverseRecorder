# Repository Guidelines

## Project Structure & Module Organization
All Swift sources live under `ReverseRecorder/`. Scene entry points (`ReverseRecorderApp.swift`, `ContentView.swift`) sit at the root, domain files stay under `Models/`, `Services/`, and `ViewModels/RecorderViewModel.swift`, and reusable SwiftUI elements live in `Views/`. Assets belong in `Assets.xcassets`. Mirror this layout when adding features so each module stays single-purpose.

## Build, Test, and Development Commands
Develop in Xcode: open `ReverseRecorder.xcodeproj`, select the `ReverseRecorder` scheme, and run on an iOS 17 simulator. Use `xcodebuild -project ReverseRecorder.xcodeproj -scheme ReverseRecorder -configuration Debug build` for CI-style builds. Run `xcodebuild test -scheme ReverseRecorder -destination 'platform=iOS Simulator,name=iPhone 15'` before each push.

## Coding Style & Naming Conventions
Follow Swift API Design Guidelines: PascalCase types, camelCase members, and one primary type per file. Indent with four spaces, keep braces on the same line, and use explicit access control. Add `// MARK:` blocks to split state, lifecycle, and helpers, and hide AVFoundation details behind small service protocols for testability.

## Testing Guidelines
Adopt XCTest; create `ReverseRecorderTests/` alongside the app target and mirror directories (`ServicesTests`, `ViewModelsTests`). Name methods `test<Action>_<Condition>_<Result>()`, and cover audio permission flows, waveform reversal, and toast timing. Target ≥80% coverage for service and view-model logic, run `xcodebuild test` locally, and attach simulator logs for audio issues.

## Commit & Pull Request Guidelines
Commits should use short, action-driven subjects—history mixes concise English and Korean messages (`Initial commit`, `1차 완성본`), so keep that brevity while favoring English for clarity. Group related changes per commit and squash noisy WIP. PRs must include user-facing impact, test evidence (command output or simulator screenshots), known limitations, and links to tracked issues. Add demo recordings or GIFs when UI behavior changes and tag the module owner.

## Security & Configuration Tips
Keep `NSMicrophoneUsageDescription` accurate whenever behavior changes. Never commit real recordings; rely on placeholder `.m4a` assets for demos. Exclude derived data and signing material from git, and move any future secrets into `.xcconfig` files.
