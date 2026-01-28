# Implementation Plan: Implement Animated Cross-Platform Tab Transitions

This plan outlines the steps to add platform-native transition animations to the app's tab navigation.

## Phase 1: Foundation and Directional Tracking
- [ ] Task: Enhance `NavigationShell` to track the "direction" of tab changes (Forward vs. Backward).
    - [ ] Write Tests: Verify direction detection logic in various scenarios.
    - [ ] Implement Feature: Add a `NavigationDirection` enum and state tracking to `NavigationShell`.
- [ ] Task: Conductor - User Manual Verification 'Foundation and Directional Tracking' (Protocol in workflow.md)

## Phase 2: Animation Implementation
- [ ] Task: Implement the `AnimatedSwitcher` or custom Transition wrapper in `NavigationShell`.
    - [ ] Write Tests: Verify the transition widget is correctly wrapping the branch content.
    - [ ] Implement Feature: Refactor `NavigationShell` build method to include transition logic.
- [ ] Task: Define platform-specific transition styles.
    - [ ] Write Tests: (Manual focus) Verify iOS-specific vs Android-specific styles.
    - [ ] Implement Feature: Add logic to switch animation curves and offsets based on `Theme.of(context).platform`.
- [ ] Task: Conductor - User Manual Verification 'Animation Implementation' (Protocol in workflow.md)

## Phase 3: Final Refinement and Cleanup
- [ ] Task: Fine-tune animation durations and curves for optimal "feel".
- [ ] Task: Ensure animations play nicely with the existing edge-swipe gesture.
- [ ] Task: Conductor - User Manual Verification 'Final Refinement and Cleanup' (Protocol in workflow.md)
