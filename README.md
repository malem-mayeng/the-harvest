# The Harvest 🌾

**Offline Sales Record Book for Farmers**

A fully offline Android app built with Flutter, designed for elderly farmers to record daily sales, track buyers, and manage pending payments — no internet needed.

## Features

- **Add Sales** — Record sales with buyer name, item sold, quantity, amount, and advance paid
- **Buyer Management** — Auto-created buyer profiles with search, edit, and delete
- **Pending Payments** — View all outstanding dues at a glance, add payments, or settle
- **Payment Tracking** — Full payment history per buyer with date-stamped transactions
- **Custom Items** — Add your own item names beyond the defaults (Fish, Vegetables)
- **Notes** — Add optional notes to any sale record
- **Settings** — Reset item list, view app version

## Design Principles

- 📱 **Fully Offline** — SQLite database, no internet required
- 👴 **Elderly-Friendly** — Large text, big buttons, high contrast, simple navigation
- 🔒 **Data Safe** — Updates preserve existing data via database migrations

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| Database | SQLite (sqflite) |
| State Management | Riverpod |
| Architecture | Repository → Service → Provider → UI |
| Target | Android (min SDK 21) |

## Project Structure

```
app/lib/
├── database/          # SQLite helper & table definitions
├── models/            # Data models (Buyer, Sale, Payment)
├── repositories/      # Database CRUD operations
├── services/          # Business logic layer
├── providers/         # Riverpod state providers
├── screens/           # UI screens
├── widgets/           # Reusable UI components
└── theme/             # App-wide theme & colors
```

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.7.2+)
- Android SDK (API 21+)
- Java 17+

## Getting Started

```bash
# Clone the repo
git clone https://github.com/malem-mayeng/the-harvest.git
cd the-harvest/app

# Install dependencies
flutter pub get

# Run on connected device / emulator
flutter run

# Run with hot reload (development)
flutter run --debug
```

## Build APK

```bash
# Release APK (optimized, smaller)
cd app
flutter build apk --release

# APK output location:
# app/build/app/outputs/flutter-apk/app-release.apk
```

To install on a device:
```bash
# Via ADB
adb install build/app/outputs/flutter-apk/app-release.apk

# Or transfer the .apk file to the phone and install manually
```

## Code Quality

```bash
# Run static analysis
flutter analyze

# Run tests
flutter test
```

## Documentation

- [V2 Implementation Plan](docs/v2_implementation_plan.md)
- [V2 Walkthrough](docs/v2_walkthrough.md)

## Version History

| Version | Description |
|---------|-------------|
| 1.0.0 | Initial release — Add sales, buyers list, pending payments |
| 2.0.0 | Payment tracking, optional fields, notes, custom items, buyer edit/delete, settings |

## License

Private project.
