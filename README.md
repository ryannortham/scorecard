# Score Card
App for AFL goal umpires to keep track of game scores

# Architecture

*Architecture diagram available in project documentation*

# UI Mockup

Source: https://miro.com/app/board/uXjVMN7hQ4Q=/

*UI mockup available in external Miro board*

# Database Schema

```mermaid
    erDiagram
        User {
            id INT PK
            name VARCHAR
            email VARCHAR
            password VARCHAR
        }
        Game {
            id INT PK
            home_team_id INT FK
            away_team_id INT FK
            location_id INT FK
            division_id INT FK
            date DATETIME
            quarter_length INT
            user_id INT FK
            is_completed BOOLEAN
        }
        Team {
            id INT PK
            name VARCHAR
            home_ground_id INT FK
        }
        Location {
            id INT PK
            name VARCHAR
            address VARCHAR
        }
        Division {
            id INT PK
            name VARCHAR(255)
        }
        Player {
            id INT PK
            name VARCHAR
            number INT
            team_id INT FK
        }
        Quarter {
            id INT PK
            game_id INT FK
            quarter_number INT
            is_completed BOOLEAN
        }
        Goal {
            id INT PK
            quarter_id INT FK
            team_id INT FK
            player_id INT FK
            is_goal BOOLEAN
            timestamp TIMESTAMP
        }
        UserPreference {
            id INT PK
            user_id INT FK
            quarter_length INT
            favorite_team_id INT FK
            countdown_timer BOOLEAN
            favorite_division_id INT FK
        }

        User ||--o{ Game : "create/write access"
        Game ||--|{ Team : "home_team_id, away_team_id"
        Team ||--|| Location : "home_ground_id"
        Game ||--|| Location : "location_id"
        Game ||--|| Division : "division_id"
        Quarter }|--|| Game : "game_id"
        Quarter ||--o{ Goal : "quarter_id"
        Player }|--|| Team : "team_id"
        Goal }o--|| Player : "player_id"
        User ||--|| UserPreference : "user_id"
        Team ||--|| UserPreference : "favorite_team_id"
        Division ||--|| UserPreference : "favorite_division_id"
```