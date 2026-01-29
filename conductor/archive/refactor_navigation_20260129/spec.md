# Specification: Refactor Navigation Architecture for Cross-Platform Consistency

## Overview

The current navigation architecture in the Scorecard app has several issues:

- Tab history is not preserved correctly (swiping back should return to the previous tab).
- Swipe-to-back on iOS is problematic or non-existent in certain scenarios.
- The tab bar remains visible on child screens, leading to a confusing UX.
- The "Game Setup" screen should be the root node, and navigating back from it should exit the app.
- Results tab navigation on Android incorrectly closes the app instead of going to the previous tab.

This track aims to refactor the navigation using `go_router` to be more idiomatic, maintainable, and provide a consistent cross-platform experience.

## Objectives

- Implement a robust `go_router` configuration that handles nested navigation and tab state correctly.
- Ensure "Game Setup" is the root of the navigation tree.
- Implement a custom "swipe back to previous tab" behavior.
- Ensure the bottom navigation bar is hidden when navigating to child screens (leaf nodes).
- Fix iOS swipe-to-back functionality across all screens.
- Standardize back-button and gesture behavior across Android and iOS.

## User Stories

- As a user, I want to swipe back from a tab to see the previous tab I was on.
- As a user, I want the navigation bar to disappear when I dive deep into a screen so I can focus on the content.
- As an iOS user, I want to be able to use the standard edge swipe gesture to navigate back.
- As a user, I want the app to close only when I am on the Game Setup screen and press back.

## Technical Requirements

- Use `StatefulShellRoute` or similar `go_router` features for persistent tab state if applicable, but customize it to support tab history in the back stack.
- Leverage `ShellRoute` for common UI elements (like the navigation bar) while ensuring child routes can be pushed "on top" of the shell.
- Implement a `RootBackButtonDispatcher` or similar logic to handle complex back-button scenarios on Android.
- Ensure `Page` transitions are platform-appropriate.

## Acceptance Criteria

- [ ] Swiping back (or pressing hardware back) from any tab (except the first one in history) returns to the previously visited tab.
- [ ] The tab bar is hidden on all "child" screens (e.g., scoring details, team edit from the team list).
- [ ] iOS swipe-to-back works on all screens, including those pushed over tabs.
- [ ] Navigating back from the "Game Setup" screen exits the app.
- [ ] Navigating back from the "Results" tab goes to the previous tab (if any) instead of exiting.
