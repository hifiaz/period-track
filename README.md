# Period Track

![App Icon](assets/icon/icon.png =250x)

A Flutter-based mobile application for tracking menstrual cycles and women's health. This app provides a smooth, native-feeling experience with optimized performance for iOS and Android devices.

## Features

- **Cycle Tracking**: Log periods, symptoms, and moods with an intuitive calendar interface.
- **Predictions**: AI-powered predictions for next cycle, fertile window, and ovulation.
- **Reminders**: Customizable notifications for upcoming periods and pill intake.
- **Health Insights**: Track weight, mood patterns, and symptoms over time.
- **Privacy-Focused**: All data stored locally with optional cloud sync.
- **Cross-Platform**: Seamless experience on iOS and Android with native performance.

The app follows iOS Human Interface Guidelines and Material Design principles for platform-specific UI, ensuring smooth 60fps animations and responsive layouts across all screen sizes.

## Tech Stack

- **Frontend**: Flutter (Dart) for cross-platform UI
- **State Management**: Provider/Riverpod for efficient state handling
- **Database**: Hive/SQflite for local storage with offline-first architecture
- **Notifications**: Flutter Local Notifications with platform-specific integration
- **Charts**: fl_chart for cycle visualization
- **Permissions**: permission_handler for camera, storage, and notification access

## Performance Optimizations

- List virtualization for smooth scrolling in cycle history
- Image caching and lazy loading for symptom icons
- Native animations using Flutter's built-in animation framework
- Memory profiling to maintain <150MB usage
- App startup time optimized to <2 seconds

## Getting Started

### Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Dart SDK (included with Flutter)
- Android Studio or Xcode for platform-specific builds
- An iOS or Android device/simulator for testing

### Installation

1. Clone the repository:
   ```bash
git clone <your-repo-url>
cd period_track
```

2. Install dependencies:
   ```bash
flutter pub get
```

3. For iOS:
   ```bash
cd ios
pod install
cd ..
```

4. Run the app:
   ```bash
flutter run
```

### Building for Release

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models (Cycle, Symptom, etc.)
├── screens/                  # UI screens (Home, Calendar, Settings)
├── services/                 # Business logic (Database, Notifications)
├── widgets/                  # Reusable UI components
└── utils/                    # Helper functions and constants
```

## Testing

Run unit tests:
```bash
flutter test
```

Run widget tests:
```bash
flutter test test/widgets/
```

Integration testing uses Flutter's integration_test package for end-to-end testing on real devices.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure code follows Dart/Flutter best practices and includes appropriate tests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, create an issue in the GitHub repository or contact the development team.

---

*Built with Flutter for optimal mobile performance and cross-platform consistency.*
