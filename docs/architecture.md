# Architecture

## Overview

Scorecard follows a clean, layered architecture pattern with clear separation of concerns. The app uses **Provider** for state management and follows Flutter's recommended best practices for building maintainable, testable applications.

## Project Structure

```text
lib/
├── main.dart                    # App entry point, provider setup, theme configuration
├── extensions/                  # Dart extension methods
│   ├── context_extensions.dart
│   ├── game_record_extensions.dart
│   └── string_extensions.dart
├── mixins/                      # Reusable behaviour mixins
│   └── selection_controller.dart
├── models/                      # Data models
│   ├── playhq.dart
│   ├── score.dart
│   └── score_worm.dart
├── providers/                   # State management (Provider pattern)
│   ├── game_record_provider.dart
│   ├── preferences_provider.dart
│   └── teams_provider.dart
├── screens/                     # Top-level screen widgets
│   ├── results/
│   │   ├── results_list_screen.dart
│   │   └── results_screen.dart
│   ├── scoring/
│   │   ├── scoring_screen.dart
│   │   └── scoring_setup_screen.dart
│   └── teams/
│       ├── team_add_screen.dart
│       ├── team_detail_screen.dart
│       └── team_list_screen.dart
├── services/                    # Business logic and external integrations
│   ├── asset_service.dart
│   ├── game_persistence_manager.dart
│   ├── game_sharing_service.dart
│   ├── game_state_service.dart
│   ├── google_maps_service.dart
│   ├── logger_service.dart
│   ├── playhq_service.dart
│   ├── results_service.dart
│   ├── score_worm_service.dart
│   ├── snackbar_service.dart
│   └── timer_manager.dart
├── theme/                       # Theme configuration
│   ├── colors.dart
│   └── design_tokens.dart
└── widgets/                     # Reusable UI components
    ├── common/
    ├── navigation/
    ├── results/
    ├── scoring/
    ├── scoring_setup/
    ├── teams/
    └── timer/
```

## State Management

### Provider Pattern

The app uses the **Provider** package for state management, with three primary providers:

1. **`UserPreferencesProvider`** (`providers/preferences_provider.dart`)
   - Manages user preferences (theme, settings)
   - Persisted using SharedPreferences
   - Notifies listeners on preference changes

2. **`GameStateService`** (`services/game_state_service.dart`)
   - Manages active game state during scoring
   - Handles score updates, quarter progression, timer state
   - Central source of truth for live games

3. **`TeamsProvider`** (`providers/teams_provider.dart`)
   - Manages team data and favourites
   - Integrates with PlayHQ API for team search
   - Persists team data locally

### Provider Initialisation

Providers are initialised at app startup in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => UserPreferencesProvider()),
    ChangeNotifierProvider(create: (_) => GameStateService()),
    ChangeNotifierProvider(create: (_) => TeamsProvider()),
  ],
  child: const FootyScoreCardApp(),
)
```

## Key Services

### Game Management

- **`GameStateService`** - Active game state management during scoring sessions
- **`GamePersistenceManager`** - Saves and loads game records to/from local storage
- **`GameSharingService`** - Handles exporting and sharing game results

### External Integrations

- **`PlayHQService`** - Integration with PlayHQ API for team search and data
- **`GoogleMapsService`** - Venue location and mapping functionality
- **`AssetService`** - Manages team logos and local assets

### Utilities

- **`TimerManager`** - Game timer functionality with quarter/period support
- **`ScoreWormService`** - Generates score progression visualisations
- **`ResultsService`** - Processes and formats game results
- **`LoggerService`** - Centralised logging with component-based categorisation
- **`SnackbarService`** - User feedback and notification management
- **`DialogService`** - Modal dialogue handling

## Navigation

The app uses a custom navigation shell with bottom navigation bar:

- **`NavigationShell`** (`widgets/navigation/navigation_shell.dart`) - Main app navigation container
- **`BottomNavBar`** (`widgets/navigation/bottom_nav_bar.dart`) - Bottom navigation UI

### Main Routes

1. **Scoring Setup** → Create new games, select teams, configure timer
2. **Teams** → Manage favourite teams, search PlayHQ, team details
3. **Results** → View game history, detailed results, score worm visualisations

## Data Flow

```text
User Interaction
      ↓
UI Widget (Screen/Component)
      ↓
Provider (State Management)
      ↓
Service (Business Logic)
      ↓
Model (Data Structure)
      ↓
Persistence (Hive/SharedPreferences)
```

### Example: Creating a New Game

1. User configures game in `ScoringSetupScreen`
2. Screen updates `GameStateService` provider
3. Provider validates and stores game state
4. User navigates to `ScoringScreen`
5. Screen reads from `GameStateService` via `Provider.of<GameStateService>(context)`
6. Score updates trigger `notifyListeners()` in provider
7. `GamePersistenceManager` saves state periodically
8. On game completion, `ResultsService` processes final results

## Design Patterns

### Repository Pattern

Services act as repositories, abstracting data access from UI components:

- `PlayHQService` - External API repository
- `GamePersistenceManager` - Local storage repository
- `TeamsProvider` - Team data repository

### Service Locator

While Provider handles state management, services are accessed through dependency injection via Provider:

```dart
final gameState = Provider.of<GameStateService>(context, listen: false);
final teams = Provider.of<TeamsProvider>(context);
```

### Extension Methods

Custom extensions enhance readability and reduce boilerplate:

- `context_extensions.dart` - BuildContext helpers (theme, navigation)
- `string_extensions.dart` - String formatting utilities
- `game_record_extensions.dart` - Game record calculations

### Mixins

Reusable behaviour is shared via mixins:

- `SelectionController` - Manages selection state for team picker

## Theme & Styling

### Material Design 3

The app uses Material Design 3 with dynamic colour support:

- **Dynamic Colour** - Adapts to system colour scheme (Android 12+)
- **Design Tokens** (`theme/design_tokens.dart`) - Centralised spacing, sizing, radii
- **Custom Colours** (`theme/colors.dart`) - Brand colours and semantic colour definitions

### Responsive Design

- Adaptive layouts for different screen sizes
- Custom `AdaptiveTitle` widget for platform-specific text rendering
- `AppScaffold` provides consistent layout structure

## Testing Strategy

### Unit Tests

- Model serialisation/deserialisation
- Service business logic
- Provider state transitions
- Extension method utilities

### Widget Tests

- Individual component rendering
- User interaction handling
- Provider integration

### Integration Tests

- End-to-end game scoring flows
- Navigation between screens
- Data persistence

Run tests with:

```bash
make test
```

## Performance Considerations

1. **Lazy Loading** - Teams and results loaded on-demand
2. **Debouncing** - Search inputs debounced to reduce API calls
3. **Efficient Rebuilds** - `Consumer` widgets limit rebuild scope
4. **Image Caching** - Team logos cached via `AssetService`
5. **Persistence** - Hive used for fast local storage (vs SQLite overhead)

## Error Handling

- **`LoggerService`** - Centralised error logging with component tags
- **Try-Catch Blocks** - Service methods handle exceptions gracefully
- **`SnackbarService`** - User-friendly error messages
- **Fallback UI** - Empty states and error widgets for failed data loads

## Future Architecture Improvements

Potential enhancements for future iterations:

- **Dependency Injection** - Consider GetIt or Riverpod for improved testability
- **Repository Layer** - Formalise repository pattern for all data access
- **Use Cases/Interactors** - Add business logic layer between UI and services
- **Clean Architecture** - Full clean architecture separation (presentation/domain/data)
- **BLoC Pattern** - Consider BLoC for more complex state scenarios

---

**Last Updated:** January 2026
