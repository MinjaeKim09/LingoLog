# Repository Agent Guidelines

## Xcode Workflow

- Prefer `xcodebuild` for repeatable builds, tests, dependency resolution, archives, and detailed failure logs.
- Use the `LingoLog.xcodeproj` project and the shared `LingoLog` scheme.
- Discover valid build destinations with:

  ```sh
  xcodebuild \
    -project LingoLog.xcodeproj \
    -scheme LingoLog \
    -showdestinations
  ```

- Build and test against an available simulator destination. Prefer a simulator UUID when reliability matters, especially in automation.
- Use Xcode through the Computer Use skill when its UI provides useful information that is not exposed cleanly through command-line tools. Examples include SwiftUI previews, target capabilities, signing settings, scheme configuration, debugger state, runtime hierarchy, and visual warnings.
- Use the Simulator UI when reproducing or verifying behavior requires taps, navigation, keyboard input, permissions, accessibility checks, or visual layout inspection.
- Edit source files directly so changes remain precise and reviewable. Do not use Xcode's editor for routine source changes.
- For long-running tasks, use this loop:

  1. Inspect the project and reproduce the issue.
  2. Build or test with `xcodebuild`.
  3. Diagnose the logs and implement the smallest appropriate change.
  4. Rebuild and rerun relevant tests.
  5. Verify visually in Xcode or Simulator when the change affects runtime behavior or UI.

- Do not use Xcode UI interaction for every build. Use it selectively for observation, configuration, debugging, and visual verification.
