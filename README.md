# DDC4000 Browser - Android App

<div align="center">

![DDC4000 Browser](https://img.shields.io/badge/DDC4000-Browser-blue?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue?style=for-the-badge&logo=flutter)
![Android](https://img.shields.io/badge/Android-5.0+-green?style=for-the-badge&logo=android)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

**Professional DDC4000 building automation interface browser for Android**

*Native Flutter app for seamless DDC4000 HVAC system management*

</div>

## 🚀 Features

### Core Functionality
- **📱 Native WebView Integration** - Optimized DDC4000 interface rendering
- **🔌 Smart Connection Management** - HTTP/HTTPS protocol switching with visual status
- **⚡ Quick Presets** - Save and load DDC4000 configurations with auto-load
- **📸 Screenshot Capture** - Native screenshot functionality with built-in gallery
- **🔄 Auto-Fit Scaling** - Intelligent interface scaling for all screen sizes

### Enhanced Mobile Features  
- **🎯 Material Design 3** - Professional DDC4000 branded interface
- **📱 Side Navigation Menu** - Easy access to all app functions
- **🔍 Fullscreen Mode** - Immersive DDC4000 interface viewing
- **🔒 Privacy Policy** - Built-in policy accessible via app menu
- **📊 Clean Status Bar** - Simplified connection status display

## 📱 Screenshots

| Home Screen | Settings | Gallery | Interface |
|-------------|----------|---------|-----------|
| *Welcome screen with connection setup* | *Protocol and IP configuration* | *Screenshot gallery view* | *DDC4000 interface browser* |

## 🛠 Technical Stack

- **Framework**: Flutter 3.32.5+
- **Language**: Dart
- **Target**: Android 5.0+ (API 21+)
- **Architecture**: MVVM with services pattern
- **Key Dependencies**:
  - `webview_flutter` - DDC4000 interface rendering
  - `screenshot` - Native screenshot capture
  - `shared_preferences` - Local data persistence
  - `permission_handler` - Android permissions management

## 📦 Installation

### Prerequisites
- Flutter SDK 3.32.5 or higher
- Android Studio with Android SDK
- Android device or emulator (API 21+)

### Build Instructions

```bash
# Clone the repository
git clone https://github.com/yourusername/ddc4000_browser_app.git
cd ddc4000_browser_app

# Install dependencies
flutter pub get

# Generate JSON serialization files
flutter packages pub run build_runner build

# Run on connected device/emulator
flutter run

# Build APK for distribution
flutter build apk --release
```

## 🔧 Configuration

### DDC4000 Connection Setup
1. **Protocol**: Choose HTTP or HTTPS based on your DDC4000 configuration
2. **IP Address**: Enter your DDC4000 device IP (e.g., 192.168.10.21)
3. **Resolution**: Select QVGA (320×240) or WVGA (800×480)

### Preset Management
- Save frequently used connections as presets
- Set auto-load preset for instant connection on app startup
- Manage multiple DDC4000 devices from one interface

## 📋 Permissions

The app requires the following Android permissions:

```xml
<!-- Network access for DDC4000 connections -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- Storage access for screenshots -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

## 🏗 Architecture

```
lib/
├── main.dart                    # App entry point and theme configuration
├── models/                      # Data models
│   ├── ddc_preset.dart         # Connection preset model
│   └── screenshot_data.dart    # Screenshot metadata model
├── services/                    # Business logic and data management
│   ├── preset_service.dart     # Preset storage and management
│   └── screenshot_service.dart # Screenshot capture and gallery management
├── screens/                     # Main application screens
│   ├── ddc_browser_screen.dart # Primary DDC4000 browser interface  
│   └── privacy_policy_screen.dart # Built-in privacy policy
└── widgets/                     # Reusable UI components
    ├── connection_settings_widget.dart
    ├── preset_selector_widget.dart
    └── screenshot_gallery_widget.dart
```

## 🚦 Usage

1. **First Launch**: Configure your DDC4000 connection settings
2. **Connect**: Tap "Connect to DDC4000" to load the interface
3. **Screenshots**: Use the camera button to capture interface screenshots
4. **Presets**: Save your configuration for quick future access
5. **Gallery**: View and manage captured screenshots

## 🔄 Development

### Running Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

### Formatting
```bash
flutter format .
```

## 📱 Web Version

This app is based on the [DDC4000 Browser Web](https://github.com/yourusername/DDC4000-Browser) version. The web version offers:
- Cross-platform browser compatibility
- No installation required
- Service Worker for offline functionality
- Progressive Web App (PWA) features

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏢 About DDC4000

DDC4000 is a building automation system for HVAC control and monitoring. This browser app provides mobile access to DDC4000 web interfaces, enabling facility managers to monitor and control building systems from anywhere.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/ddc4000_browser_app/issues)
- **Documentation**: [Wiki](https://github.com/yourusername/ddc4000_browser_app/wiki)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/ddc4000_browser_app/discussions)

---

<div align="center">

**Built with ❤️ for building automation professionals**

</div>
