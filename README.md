# 🌌 GalaxyScholars

**GalaxyScholars** is a cross-platform Flutter application aimed at enhancing the learning experience through interactive and user-friendly interfaces.

---

## 🚀 Features

- 📱 Cross-platform support: Android, iOS, Web, Windows, macOS, and Linux
- 🎨 Modern and responsive UI design
- 📚 Educational content delivery
- 🔍 Search functionality for courses and materials
- 🧠 Quiz and assessment modules
- 🗂️ Organized course categorization

---


## 🛠️ Getting Started

### Prerequisites

- Flutter SDK (v3.10.0 or higher)  
- Dart SDK (v3.0.0 or higher)  
- IDE (VS Code or Android Studio with Flutter & Dart plugins)

### Flutter Setup

```bash
# Check Flutter installation
flutter doctor 

# Enable platforms
flutter config --enable-web
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop
```

### Installation

# Clone the repo
git clone https://github.com/karthyick/galaxyscholarss.git
cd galaxyscholarss

# Install dependencies
flutter pub get

# Run app in development mode
flutter run

# Run in release mode
flutter run --release


📁 Project Structure
```
galaxyscholarss/
├── android/              # Android-specific files
├── ios/                  # iOS-specific files
├── web/                  # Web-specific files
├── windows/              # Windows-specific files
├── macos/                # macOS-specific files
├── linux/                # Linux-specific files
├── lib/
│   ├── config/           # App configuration
│   │   ├── routes.dart
│   │   └── theme.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── services/
│   │   └── utils/
│   ├── data/
│   │   ├── models/
│   │   ├── providers/
│   │   └── repositories/
│   ├── features/
│   │   ├── auth/
│   │   ├── courses/
│   │   ├── quiz/
│   │   └── profile/
│   ├── ui/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── shared/
│   └── main.dart
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── assets/
│   ├── images/
│   ├── fonts/
│   └── animations/
└── pubspec.yaml
```

🤝 Contributing
# Fork and create your feature branch
git checkout -b feature/amazing-feature

# Commit your changes
git commit -m "Add some amazing feature"

# Push to the branch
git push origin feature/amazing-feature


📬 Contact
Karthick Raja M
🔗 LinkedIn - https://linkedin.com/in/karthyick

