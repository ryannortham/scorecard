# File Naming Conventions

This document describes the file naming conventions established for the Scorecard app, the problems that prompted this refactoring, and the approaches taken to resolve them.

## Problems Identified

### 1. Inconsistent Use of Suffixes

**Problem:** File suffixes mirroring parent folder names (e.g. `_models`, `_provider`, `_service`) were applied inconsistently across the codebase.

| Pattern | Before |
|---------|--------|
| `*_service.dart` | Consistently applied |
| `*_provider.dart` | Missing on `game_record.dart` |
| `*_models.dart` | Applied to some model files |

**Solution:** Established clear suffix conventions:
- **Services** → `_service.dart` suffix (required)
- **Providers** → `_provider.dart` suffix (required)
- **Models** → No suffix (use domain name directly, e.g. `playhq.dart` not `playhq_models.dart`)
- **Screens** → `_screen.dart` suffix (required)
- **Extensions** → `_extensions.dart` suffix (required)

### 2. File Names Not Matching Primary Class

**Problem:** Several files had names that didn't match their primary public class.

| File | Class |
|------|-------|
| `mesh_background.dart` | `AtmosphericBackground` |
| `dialog_helpers.dart` | `DialogService` |

**Solution:** File names should match the primary public class (converted to snake_case). Classes were renamed to match the more descriptive file names:
- `AtmosphericBackground` → `MeshBackground`
- File renamed to `dialog_service.dart` to match `DialogService`

### 3. Verbose File Names

**Problem:** Many file names contained redundant words that added length without clarity.

| Before | After |
|--------|-------|
| `app_logger_service.dart` | `logger_service.dart` |
| `app_bottom_navigation_bar.dart` | `bottom_nav_bar.dart` |
| `playhq_graphql_service.dart` | `playhq_service.dart` |
| `user_preferences_provider.dart` | `preferences_provider.dart` |
| `game_settings_configuration.dart` | `timer_config.dart` |
| `team_selection_widget.dart` | `team_selector.dart` |
| `app_sliver_app_bar.dart` | `sliver_app_bar.dart` |

**Solution:** Remove redundant prefixes/suffixes:
- Remove `app_` prefix (implied by being in the app)
- Remove `_widget` suffix (implied by being in `widgets/`)
- Use concise but descriptive names

### 4. Messy Widget Directory Structure

**Problem:** The `widgets/` directory had inconsistent organisation with many sparse directories containing only 1-2 files, while others had 10+ files.

| Directory | Files Before |
|-----------|--------------|
| `decorative/` | 1 |
| `dialogs/` | 1 |
| `icons/` | 1 |
| `layout/` | 2 |
| `menu/` | 1 |
| `text/` | 1 |
| `team_add/` | 1 |
| `team_detail/` | 3 |
| `teams/` | 1 |
| `scoring/` | 10 |

**Solution:** Consolidated sparse directories by purpose:
- Created `common/` for shared/utility widgets
- Merged team-related widgets into `teams/`
- Renamed `game_setup/` to `scoring_setup/` to align with screen naming

### 5. Colour Service in Wrong Location

**Problem:** `color_service.dart` was in `services/` but it's fundamentally about theming, not business logic.

**Solution:** Moved to `theme/colors.dart` alongside `theme/design_tokens.dart`.

### 6. Inconsistent Terminology (Settings/Setup/Preferences)

**Problem:** Mixed terminology around configuration concepts.

**Analysis:**
- **Preferences** = User-persisted choices (theme, favourite team) → `PreferencesProvider`
- **Setup** = One-time game configuration before starting → `ScoringSetupScreen`
- **Settings** = Was confusingly named for timer configuration

**Solution:** 
- Renamed `GameSettingsConfiguration` → `TimerConfig` (more specific)
- Renamed `game_setup/` → `scoring_setup/` (aligns with `ScoringSetupScreen`)

## Conventions Established

### File Naming

| Type | Convention | Example |
|------|------------|---------|
| Models | Domain name, no suffix | `playhq.dart`, `score.dart` |
| Providers | Domain + `_provider` | `preferences_provider.dart` |
| Services | Domain + `_service` | `logger_service.dart` |
| Screens | Feature + `_screen` | `scoring_setup_screen.dart` |
| Extensions | Domain + `_extensions` | `string_extensions.dart` |
| Widgets | Descriptive, concise | `team_selector.dart` |

### Class Naming

- File name should match primary public class (in snake_case)
- Multiple tightly-coupled classes in one file is acceptable (e.g. widget + private helpers)
- Private helper widgets should be prefixed with `_`

### Directory Structure

```
lib/
├── extensions/          # Extension methods on existing types
├── mixins/              # Reusable mixins for classes
├── models/              # Data models and DTOs
├── providers/           # State management (ChangeNotifier)
├── screens/             # Full-page widgets
│   ├── results/
│   ├── scoring/
│   └── teams/
├── services/            # Business logic and external integrations
├── theme/               # Theming (colours, design tokens)
└── widgets/             # Reusable UI components
    ├── common/          # Shared/utility widgets
    ├── navigation/      # Navigation-related widgets
    ├── results/         # Results feature widgets
    ├── scoring/         # Scoring feature widgets
    ├── scoring_setup/   # Scoring setup feature widgets
    ├── teams/           # Teams feature widgets
    └── timer/           # Timer feature widgets
```

### Widget Directory Guidelines

- **Feature folders** (e.g. `scoring/`, `teams/`) should contain widgets used primarily by that feature
- **Common folder** contains widgets shared across multiple features
- Minimum 2-3 files before creating a dedicated folder
- Consider consolidating if a folder has only 1 file

## Changes Summary

### Files Renamed

| Before | After |
|--------|-------|
| `models/playhq_models.dart` | `models/playhq.dart` |
| `models/score_models.dart` | `models/score.dart` |
| `models/score_worm_data.dart` | `models/score_worm.dart` |
| `providers/game_record.dart` | `providers/game_record_provider.dart` |
| `providers/user_preferences_provider.dart` | `providers/preferences_provider.dart` |
| `services/app_logger_service.dart` | `services/logger_service.dart` |
| `services/playhq_graphql_service.dart` | `services/playhq_service.dart` |
| `services/color_service.dart` | `theme/colors.dart` |
| `widgets/decorative/mesh_background.dart` | `widgets/common/mesh_background.dart` |
| `widgets/dialogs/dialog_helpers.dart` | `widgets/common/dialog_service.dart` |
| `widgets/icons/football_icon.dart` | `widgets/common/football_icon.dart` |
| `widgets/layout/app_scaffold.dart` | `widgets/common/app_scaffold.dart` |
| `widgets/layout/app_sliver_app_bar.dart` | `widgets/common/sliver_app_bar.dart` |
| `widgets/menu/app_menu.dart` | `widgets/common/app_menu.dart` |
| `widgets/text/adaptive_title.dart` | `widgets/common/adaptive_title.dart` |
| `widgets/team_add/team_search_results.dart` | `widgets/teams/team_search_results.dart` |
| `widgets/team_detail/team_action_buttons.dart` | `widgets/teams/team_action_buttons.dart` |
| `widgets/team_detail/team_address_section.dart` | `widgets/teams/team_address_section.dart` |
| `widgets/team_detail/team_no_address_section.dart` | `widgets/teams/team_no_address_section.dart` |
| `widgets/game_setup/game_settings_configuration.dart` | `widgets/scoring_setup/timer_config.dart` |
| `widgets/game_setup/team_selection_widget.dart` | `widgets/scoring_setup/team_selector.dart` |
| `widgets/navigation/app_bottom_navigation_bar.dart` | `widgets/navigation/bottom_nav_bar.dart` |

### Classes Renamed

| Before | After |
|--------|-------|
| `AtmosphericBackground` | `MeshBackground` |
| `GameSettingsConfiguration` | `TimerConfig` |
| `TeamSelectionWidget` | `TeamSelector` |
| `AppBottomNavigationBar` | `BottomNavBar` |

### Directories Deleted

- `widgets/decorative/`
- `widgets/dialogs/`
- `widgets/icons/`
- `widgets/layout/`
- `widgets/menu/`
- `widgets/text/`
- `widgets/team_add/`
- `widgets/team_detail/`
- `widgets/game_setup/`

## References

- [Effective Dart: Style](https://dart.dev/effective-dart/style) - Official Dart naming conventions
- [Flutter App Architecture Guide](https://docs.flutter.dev/app-architecture/guide) - Official Flutter architecture recommendations
- [Feature-first vs Layer-first](https://codewithandrea.com/articles/flutter-project-structure/) - Project structure approaches
