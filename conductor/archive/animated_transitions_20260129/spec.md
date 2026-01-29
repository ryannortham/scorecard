# Specification: Implement Animated Cross-Platform Tab Transitions

## Overview

Currently, the app's tab navigation (handled by `go_router` and `StatefulShellRoute`) uses "hard cuts" when switching branches. While functional, this lacks the premium, native feel found in high-quality iOS and Android applications. This track aims to implement platform-appropriate transition animations for tab switching within the `NavigationShell`.

## Objectives

- Replace hard cuts with smooth, platform-native transitions for tab switching.
- On iOS: Implement a "card stack" or "sliding" transition that feels native to the platform.
- On Android: Implement a subtle fade or slide transition appropriate for Material Design 3.
- Ensure transitions are consistent with child screen animations already present in the app.
- Maintain the custom tab history and back-gesture logic implemented in the previous track.

## User Stories

- As a user, I want the UI to smoothly transition when I switch tabs so that the app feels more polished and responsive.
- As an iOS user, I want tab transitions to feel like standard iOS navigation animations.
- As an Android user, I want transitions to follow modern Material Design patterns.

## Technical Requirements

- Leverage `AnimatedSwitcher`, `PageTransition`, or custom `AnimationController` within `NavigationShell`.
- Detect the "direction" of navigation (forward vs. backward in history) to apply appropriate animations (e.g., sliding right-to-left vs. left-to-right).
- Ensure animations do not introduce noticeable latency or UI jank.
- Verify that the `PopScope` and `GestureDetector` logic remains fully functional.

## Acceptance Criteria

- [ ] Switching tabs triggers a smooth transition animation.
- [ ] The animation style changes based on the target platform (iOS vs. Android).
- [ ] Backward navigation (via back button or swipe) uses a reverse animation.
- [ ] Animations are performant and do not glitch during rapid tab switching.
