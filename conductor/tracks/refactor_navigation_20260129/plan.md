# Implementation Plan: Refactor Navigation Architecture

This plan outlines the steps to refactor the navigation using `go_router` to resolve tab history, iOS swipe-to-back, and visibility issues.

## Phase 1: Analysis and Foundation
- [x] Task: Analyze current `AppRouter` and `main.dart` implementation.
- [x] Task: Research `go_router` best practices for tab history and hiding shell UI on child routes.
- [x] Task: Conductor - User Manual Verification 'Analysis and Foundation' (Protocol in workflow.md)
  [checkpoint: f47f90c]

## Phase 2: Core Navigation Refactoring
- [x] Task: Define the new `go_router` structure with Game Setup as the root node.
    - [x] Write Tests: Verify root route points to Game Setup and other routes are accessible.
    - [x] Implement Feature: Update `AppRouter` configuration.
- [x] Task: Implement `StatefulShellRoute` for tabs while maintaining a custom navigation history stack.
    - [x] Write Tests: Verify tab switching and history tracking logic.
    - [x] Implement Feature: Refactor tab navigation to use the new shell route and history management.
- [x] Task: Ensure the Bottom Navigation Bar is hidden on child screens.
    - [x] Write Tests: Verify visibility of navigation bar on root vs child screens.
    - [x] Implement Feature: Adjust route hierarchy so child screens are pushed above the shell.
- [x] Task: Conductor - User Manual Verification 'Core Navigation Refactoring' (Protocol in workflow.md)
  [checkpoint: b5e1556]

## Phase 3: Platform-Specific Refinements
- [x] Task: Fix iOS Swipe-to-Back and ensure it integrates with the tab history.
    - [x] Write Tests: (Manual Verification focus) Verify gesture behavior on iOS.
    - [x] Implement Feature: Adjust `Page` builders and transitions for iOS compatibility.
- [x] Task: Refine Android Back Button behavior for tabs and app exit.
    - [x] Write Tests: Verify back button on Game Setup exits app and on tabs goes to previous tab.
    - [x] Implement Feature: Implement custom `BackButtonDispatcher` or `PopScope` logic.
- [x] Task: Conductor - User Manual Verification 'Platform-Specific Refinements' (Protocol in workflow.md)
  [checkpoint: e73d422]

## Phase 4: Final Verification and Cleanup
- [x] Task: Perform comprehensive cross-platform testing (Android and iOS).
- [x] Task: Remove any legacy navigation code and unused dependencies.
- [x] Task: Conductor - User Manual Verification 'Final Verification and Cleanup' (Protocol in workflow.md)
  [checkpoint: 76809]
