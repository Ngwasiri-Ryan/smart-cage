# SmartCage — ChirpGuard Flutter App

A pixel-perfect Flutter replica of `smart-cage.html`. Frontend-only, no backend.

## Features
- 3-slide animated onboarding
- Dashboard: AI summary, 4 sensor cards (temp, NH3, feed, weather), 7-day forecast, 24h temperature chart
- Ammonia Screen: animated gas chamber with floating particles, clinical diagnostics, 12-week heatmap, NH3 trend chart
- Feed History: 7-day bar chart with decline highlighting, 3-interval telemetry
- Alerts Log: scrollable colour-coded alert list with toast notifications
- Arduino Hardware Simulator drawer: live sliders for temperature & NH3, feed interval inputs, 4 preset scenarios
- Real-time relay state indicators (Heater / Fan)

## Setup

### 1. Install Flutter
Download and install Flutter SDK from https://flutter.dev/docs/get-started/install

### 2. Generate platform files
Open a terminal **inside** the `smart-cage` folder and run:

```bash
flutter create . --project-name smart_cage --org com.chirpguard
```
> This generates the Android/iOS/Web platform folders while preserving your `lib/` source files.

### 3. Install packages
```bash
flutter pub get
```

### 4. Run the app
```bash
# Android / iOS (device/emulator must be connected)
flutter run

# Web browser
flutter run -d chrome

# Windows desktop
flutter run -d windows
```

## Project Structure
```
lib/
├── main.dart                     # App entry point
├── theme/
│   └── app_colors.dart           # Tailwind-mapped colour palette
├── models/
│   └── app_state.dart            # ChangeNotifier state + all business logic
├── screens/
│   ├── onboarding_screen.dart    # 3-slide onboarding
│   ├── main_shell.dart           # Header, status banner, nav, drawer, toasts
│   ├── dashboard_screen.dart     # Home tab
│   ├── ammonia_screen.dart       # Ammonia tab
│   ├── feed_history_screen.dart  # Feed tab
│   └── alerts_screen.dart        # Alerts tab
└── widgets/
    ├── gas_chamber.dart          # Animated particle gas visualiser
    └── simulator_drawer.dart     # Bottom sheet hardware simulator
```

## Dependencies
| Package | Purpose |
|---|---|
| `provider` | State management |
| `fl_chart` | Line and bar charts |
| `google_fonts` | Inter font |
| `intl` | Date formatting |
