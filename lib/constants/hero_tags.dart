// hero tag constants for cross-screen animations

/// Shared hero tag for the primary action FAB across tab screens.
/// Used by StartScoringFab and AddTeam FAB to enable smooth Hero
/// transitions when switching between the Scoring and Teams tabs.
const String primaryActionFabHeroTag = 'primary_action_fab';

/// Generates a hero tag for a team's logo.
/// Used for Hero transitions between team list and detail screens.
String teamLogoHeroTag(String teamName) => 'team_logo_$teamName';

/// Hero tag for the home team logo in scoring flow.
/// Used for transitions from setup screen to scoring screen.
const String scoringHomeLogoHeroTag = 'scoring_home_logo';

/// Hero tag for the away team logo in scoring flow.
/// Used for transitions from setup screen to scoring screen.
const String scoringAwayLogoHeroTag = 'scoring_away_logo';
