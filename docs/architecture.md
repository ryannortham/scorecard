# Architecture

## Overview

Scorecard follows a clean, layered **MVVM (Model-View-ViewModel)** architecture pattern with clear separation of concerns. The app uses **Provider** for state management and follows Flutter's recommended best practices for building maintainable, testable applications.

The architecture distinguishes between:

- **ViewModels** - Stateful `ChangeNotifier` classes managing UI state
- **Services** - Stateless utility classes for external integrations and helpers
- **Repositories** - Data access layer abstracting persistence

## Project Structure

```text
lib/
├── main.dart                    # App entry point, provider setup, theme configuration
├── extensions/                  # Dart extension methods
│   ├── context_extensions.dart
│   ├── game_record_extensions.dart
│   └── string_extensions.dart
├── mixins/                      # Reusable behaviour mixins
│   └── selection_mixin.dart
├── models/                      # Data models (immutable data structures)
│   ├── game_record.dart
│   ├── game_summary.dart
│   ├── playhq.dart
│   ├── score.dart
│   └── score_worm.dart
├── repositories/                # Data access layer (Repository pattern)
│   ├── game_repository.dart
│   ├── preferences_repository.dart
│   ├── shared_prefs_game_repository.dart
│   ├── shared_prefs_preferences_repository.dart
│   ├── shared_prefs_team_repository.dart
│   └── team_repository.dart
├── screens/                     # Top-level screen widgets (Views)
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
├── services/                    # STATELESS utilities and external integrations
│   ├── asset_service.dart
│   ├── dialog_service.dart
│   ├── game_sharing_service.dart
│   ├── google_maps_service.dart
│   ├── logger_service.dart
│   ├── playhq_service.dart
│   ├── score_table_builder_service.dart
│   ├── score_worm_service.dart
│   └── snackbar_service.dart
├── theme/                       # Theme configuration
│   ├── colors.dart
│   └── design_tokens.dart
├── viewmodels/                  # STATEFUL ChangeNotifiers (UI state management)
│   ├── game_persistence_manager.dart  # Internal helper for GameViewModel
│   ├── game_view_model.dart
│   ├── preferences_view_model.dart
│   ├── teams_view_model.dart
│   └── timer_manager.dart             # Internal helper for GameViewModel
└── widgets/                     # Reusable UI components
    ├── common/
    ├── navigation/
    ├── results/
    ├── scoring/
    ├── scoring_setup/
    ├── teams/
    └── timer/
```

## MVVM Architecture

### ViewModels (Stateful)

ViewModels are `ChangeNotifier` classes that manage UI state. They are the single source of truth for their respective domains and notify listeners when state changes.

Located in `lib/viewmodels/`:

1. **`GameViewModel`** (`viewmodels/game_view_model.dart`)
   - Manages active game state during scoring sessions
   - Handles score updates, quarter progression, timer state
   - Uses `GameRepository` for persistence (injectable for testing)
   - Central source of truth for live games
   - Internal helpers: `TimerManager`, `GamePersistenceManager`

2. **`PreferencesViewModel`** (`viewmodels/preferences_view_model.dart`)
   - Manages user preferences (theme, settings, favourite teams)
   - Uses `PreferencesRepository` for persistence (injectable for testing)
   - Notifies listeners on preference changes

3. **`TeamsViewModel`** (`viewmodels/teams_view_model.dart`)
   - Manages team data and team list
   - Uses `TeamRepository` for persistence (injectable for testing)

### Services (Stateless)

Services are stateless utility classes that provide functionality without managing state. They handle external integrations, data transformations, and side effects.

Located in `lib/services/`:

- **`AssetService`** - Manages team logos and local assets
- **`DialogService`** - Material 3 compliant dialogs and prompts
- **`GameSharingService`** - Handles exporting and sharing game results
- **`GoogleMapsService`** - Venue location and mapping functionality
- **`LoggerService`** - Centralised logging with component-based categorisation
- **`PlayHQService`** - Integration with PlayHQ API for team search and data
- **`ScoreTableBuilderService`** - Builds score table widgets with proper data handling
- **`ScoreWormService`** - Generates score progression visualisations
- **`SnackbarService`** - User feedback and notification management

### Repositories (Data Access)

The repository pattern abstracts data persistence, enabling testability:

Located in `lib/repositories/`:

- **`GameRepository`** - Interface for game data CRUD operations
- **`TeamRepository`** - Interface for team data persistence
- **`PreferencesRepository`** - Interface for user preferences

Default implementations use SharedPreferences:

- `SharedPrefsGameRepository`
- `SharedPrefsTeamRepository`
- `SharedPrefsPreferencesRepository`

## State Management

### Provider Pattern

The app uses the **Provider** package for state management with ViewModels:

```dart
MultiProvider(
  providers: [
    Provider<GameRepository>(create: (_) => SharedPrefsGameRepository()),
    ChangeNotifierProvider(create: (_) => PreferencesViewModel()),
    ChangeNotifierProvider(create: (_) => GameViewModel()),
    ChangeNotifierProvider(create: (_) => TeamsViewModel()),
  ],
  child: const FootyScoreCardApp(),
)
```

### Accessing ViewModels

```dart
// With listening (rebuilds on changes)
final teams = Provider.of<TeamsViewModel>(context);
final teams = context.watch<TeamsViewModel>();

// Without listening (one-time access)
final gameState = Provider.of<GameViewModel>(context, listen: false);
final gameState = context.read<GameViewModel>();
```

### Dependency Injection for Testing

ViewModels accept optional repository parameters for testing:

```dart
class TeamsViewModel extends ChangeNotifier {
  TeamsViewModel({TeamRepository? repository})
    : _repository = repository ?? SharedPrefsTeamRepository();
}

// Production
final viewModel = TeamsViewModel(); // Uses SharedPrefsTeamRepository

// Testing
final mockRepo = MockTeamRepository(initialTeams: [Team(name: 'Test')]);
final viewModel = TeamsViewModel(repository: mockRepo);
```

## Navigation

The app uses a custom navigation shell with bottom navigation bar:

- **`NavigationShell`** (`widgets/navigation/navigation_shell.dart`) - Main app navigation container
- **`BottomNavBar`** (`widgets/navigation/bottom_nav_bar.dart`) - Bottom navigation UI

### Main Routes

1. **Scoring Setup** - Create new games, select teams, configure timer
2. **Teams** - Manage favourite teams, search PlayHQ, team details
3. **Results** - View game history, detailed results, score worm visualisations

## Data Flow

```text
User Interaction
      |
      v
UI Widget (Screen/Component) --- View
      |
      v
ViewModel (State Management) --- ViewModel
      |
      v
Repository (Data Access)     --- Model/Data Layer
      |
      v
Persistence (SharedPreferences)
```

### Example: Creating a New Game

1. User configures game in `ScoringSetupScreen`
2. Screen updates `GameViewModel` via Provider
3. ViewModel validates and stores game state
4. User navigates to `ScoringScreen`
5. Screen reads from `GameViewModel` via `context.watch<GameViewModel>()`
6. Score updates trigger `notifyListeners()` in ViewModel
7. `GamePersistenceManager` saves state periodically
8. On game completion, results are persisted via `GameRepository`

## Design Patterns

### Repository Pattern

Data access is abstracted behind repository interfaces, enabling:

- **Testability** - Mock implementations can be injected for unit tests
- **Flexibility** - Storage backend can be swapped (e.g., SQLite, cloud sync)
- **Separation of concerns** - Business logic decoupled from persistence details

Repository structure:

```text
repositories/
├── game_repository.dart                    # Abstract interface
├── shared_prefs_game_repository.dart       # SharedPreferences implementation
├── team_repository.dart                    # Abstract interface
├── shared_prefs_team_repository.dart       # SharedPreferences implementation
├── preferences_repository.dart             # Abstract interface + PreferencesData
└── shared_prefs_preferences_repository.dart # SharedPreferences implementation
```

### Extension Methods

Custom extensions enhance readability and reduce boilerplate:

- `context_extensions.dart` - BuildContext helpers (theme, navigation)
- `string_extensions.dart` - String formatting utilities
- `game_record_extensions.dart` - Game record calculations

### Mixins

Reusable behaviour is shared via mixins:

- `SelectionMixin` - Manages selection state for team picker widgets

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

### Test Structure

```text
test/
├── mocks/                          # Mock implementations
│   ├── mock_game_repository.dart
│   ├── mock_preferences_repository.dart
│   └── mock_team_repository.dart
├── models/                         # Model tests
│   ├── game_record_test.dart
│   └── score_test.dart
├── repositories/                   # Repository tests
│   └── mock_game_repository_test.dart
├── services/                       # Service tests
│   └── game_state_service_test.dart
├── viewmodels/                     # ViewModel tests
│   ├── preferences_view_model_test.dart
│   └── teams_view_model_test.dart
└── ...
```

### Unit Tests

- Model serialisation/deserialisation
- Service business logic
- ViewModel state transitions (using mock repositories)
- Extension method utilities

### Widget Tests

- Individual component rendering
- User interaction handling
- ViewModel integration

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
5. **Persistence** - SharedPreferences used for fast local storage

## Error Handling

- **`LoggerService`** - Centralised error logging with component tags
- **Try-Catch Blocks** - Service methods handle exceptions gracefully
- **`SnackbarService`** - User-friendly error messages
- **Fallback UI** - Empty states and error widgets for failed data loads

---

**Last Updated:** January 2026
