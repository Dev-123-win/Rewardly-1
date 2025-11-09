# Rewardly Flutter App - AI Agent Instructions

## Project Overview
This is a Flutter-based mobile app that implements a rewards and gaming platform. The app integrates multiple mini-games (like Whack-a-Mole, Tic-Tac-Toe, Spin and Win) with ad-based rewards and user transactions.

## Architecture & Structure

### Core Components
- `lib/core/`: Central services and utilities
  - `navigation/`: Uses singleton NavigationService for app-wide routing
  - `services/`: ConfigService and GameService manage global state
  - `theme/`: Centralized theming with app_colors.dart and app_typography.dart

### State Management
- Provider pattern used throughout (`lib/providers/`)
- Multiple provider variants exist for ad and user management:
  - `ad_provider_new.dart` and `ad_provider.dart`
  - `user_provider_new.dart`, `user_provider_temp.dart`, and `user_provider.dart`
  When modifying user/ad functionality, check all provider variants.

### Data Flow
1. User actions trigger provider methods
2. Providers interact with repositories (`lib/data/repositories/`)
3. Repositories handle Firebase/local storage via queue system (`write_queue.dart`)

### UI Architecture
- Responsive design pattern with paired screens:
  Example: `profile_screen.dart` and `responsive_profile_screen.dart`
- Common widgets in `lib/widgets/` for reuse
- Theme consistency maintained through `core/theme/`

## Key Integration Points

### Firebase Integration
- Authentication: Google Sign-In (`auth_provider.dart`)
- Firestore: User data and transactions
- Required files:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`

### AdMob Integration
- Ad implementations in `ad_provider_new.dart`
- Milestones and rewards tracked in `models/ad_milestone.dart`

## Development Workflows

### Setup
```bash
flutter pub get
# Configure Firebase CLI if needed
```

### Local Development
- Enable Firebase emulator for local testing
- Use responsive screens for device-specific testing
- Asset updates require updating both `pubspec.yaml` and asset directories

### Game Development
When adding new games:
1. Create game logic in `lib/games/[game_name]/`
2. Add corresponding provider in `lib/providers/`
3. Create responsive and standard screen variants
4. Update reward system in ad providers

## Project Conventions

### File Naming
- Responsive screens prefixed with `responsive_`
- New features should have both standard and responsive variants
- Providers suffixed with their state: `_new`, `_temp` for transitions

### State Management
- Use Provider for simple state
- Complex state flows through repository layer
- Cache sensitive data through `cache_manager.dart`

### Asset Management
- Game assets go in `assets/games/[game_name]/`
- Shared assets at root of `assets/`
- Custom fonts declared in both `pubspec.yaml` and assets