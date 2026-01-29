# Product Guidelines

## Project Phase: Polishing & Refinement

The application is feature-complete. The current focus is on high-quality polish, resolving navigation edge cases, and ensuring a seamless user experience.

## Visual Identity & Cross-Platform UX

- **Unified Experience:** Ensure a consistent user experience across both Android and iOS. While adhering to Material Design 3 as the base design system, verify that interactions feel natural on both platforms.
- **Material Design 3 Consistency:** Use Material Design 3 components as the primary design language. On iOS, ensure these components are implemented in a way that doesn't conflict with system gestures (e.g., swipe to go back).
- **Motion & Transitions:** Navigation between screens should be smooth and predictable. Use adaptive page transitions where appropriate, or a consistent custom transition that works well on both platforms. Eliminate jarring jumps or ambiguous state changes.
- **Clarity:** Maintain high contrast and clear visual hierarchy, ensuring the app remains usable in outdoor conditions (e.g., bright sunlight for umpires).

## Navigation & UX Patterns

- **Predictable Routing:** Ensure the back stack is managed correctly on both platforms. Users should never get trapped or exit the app unexpectedly. Pay special attention to the difference between Android's hardware back button and iOS's swipe-to-back gesture.
- **Feedback:** Provide immediate visual feedback for all user interactions (taps, saves, errors).
- **Consistency:** Ensure iconography and terminology are consistent across all screens (e.g., "Results" vs. "History").

## Prose Style

- **Professional & Functional:** Text should be concise, unambiguous, and helpful. Avoid slang. Focus on clarity for officials and coaches who need to record data quickly.
