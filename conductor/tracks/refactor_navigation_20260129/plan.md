# Implementation Plan: Refactor Navigation Architecture

This plan outlines the steps to refactor the navigation using `go_router` to resolve tab history, iOS swipe-to-back, and visibility issues.

## Phase 1: Analysis and Foundation
- [ ] Task: Analyze current `AppRouter` and `main.dart` implementation.
- [ ] Task: Research `go_router` best practices for tab history and hiding shell UI on child routes.
- [ ] Task: Conductor - User Manual Verification 'Analysis and Foundation' (Protocol in workflow.md)

## Phase 2: Core Navigation Refactoring
- [ ] Task: Define the new `go_router` structure with Game Setup as the root node.
    - [ ] Write Tests: Verify root route points to Game Setup and other routes are accessible.
    - [ ] Implement Feature: Update `AppRouter` configuration.
- [ ] Task: Implement `StatefulShellRoute` for tabs while maintaining a custom navigation history stack.
    - [ ] Write Tests: Verify tab switching and history tracking logic.
    - [ ] Implement Feature: Refactor tab navigation to use the new shell route and history management.
- [ ] Task: Ensure the Bottom Navigation Bar is hidden on child screens.
    - [ ] Write Tests: Verify visibility of navigation bar on root vs child screens.
    - [ ] Implement Feature: Adjust route hierarchy so child screens are pushed above the shell.
- [ ] Task: Conductor - User Manual Verification 'Core Navigation Refactoring' (Protocol in workflow.md)

## Phase 3: Platform-Specific Refinements
- [ ] Task: Fix iOS Swipe-to-Back and ensure it integrates with the tab history.
    - [ ] Write Tests: (Manual Verification focus) Verify gesture behavior on iOS.
    - [ ] Implement Feature: Adjust `Page` builders and transitions for iOS compatibility.
- [ ] Task: Refine Android Back Button behavior for tabs and app exit.
    - [ ] Write Tests: Verify back button on Game Setup exits app and on tabs goes to previous tab.
    - [ ] Implement Feature: Implement custom `BackButtonDispatcher` or `PopScope` logic.
- [ ] Task: Conductor - User Manual Verification 'Platform-Specific Refinements' (Protocol in workflow.md)

## Phase 4: Final Verification and Cleanup
- [ ] Task: Perform comprehensive cross-platform testing (Android and iOS).
- [ ] Task: Remove any legacy navigation code and unused dependencies.
- [ ] Task: Conductor - User Manual Verification 'Final Verification and Cleanup' (Protocol in workflow.md)
