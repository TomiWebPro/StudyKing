# StudyKing

A modern Flutter-based adaptive learning platform designed for efficient study management and AI-powered content generation.

## ✨ Features

- **Subject Management**: Organize your study topics with ease
- **Practice Sessions**: Adaptive practice with AI-generated questions
- **AI-Powered Content**: Dynamic model selection from OpenRouter API
- **Progress Tracking**: Monitor your study sessions and performance
- **Flexible Settings**: Customize themes, fonts, and AI configurations
- **Responsive UI**: Clean Material Design 3 interface

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.41.7 or higher
- Dart SDK
- Firebase/Hive for local storage (pre-configured)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/TomiWebPro/StudyKing.git
   cd StudyKing
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

4. For web deployment:
   ```bash
   flutter build web --release
   python3 -m http.server 8080 -d build/web
   ```

## 📱 Platform Support

- ✅ Web (Primary target)
- ✅ Android (via Flutter Web build)
- 🚧 iOS (work in progress)
- 🚧 Desktop (work in progress)

## 🔧 Configuration

### API Keys

The app uses dynamic AI model fetching from OpenRouter. Configure your API key in:
- Settings → AI Configuration → Manage Credentials
- Or set via environment variable: `OPENROUTER_API_KEY`

### Database

The app uses Hive for local storage. All data is stored locally in:
- `subjects` box
- `topics` box
- `questions` box
- `attempts` box
- `lessons` box
- `sessions` box

## 🎯 Features in Development

- [ ] Dynamic AI model selection from API
- [ ] PDF ingestion pipeline
- [ ] Spaced repetition algorithm
- [ ] Multi-modal content support (text, PDF, video)
- [ ] Smart notifications
- [ ] Collaborative study features

## 🛠️ Tech Stack

- **Framework**: Flutter 3.41.7
- **State Management**: Riverpod
- **Database**: Hive
- **AI Backend**: OpenRouter API
- **UI**: Material Design 3

## 📄 License

This project is licensed under the **Modified MIT License with GURAv1 Addendum**.

See the [LICENSE](LICENSE) file for the full license text.

**IMPORTANT**: This license includes a Geographic Use Restriction Addendum (GURAv1). See the addendum at:
https://github.com/TomiWebPro/Geographic-Use-Restriction-Addendum

By using this software, you agree to the geographic use restrictions outlined in the GURAv1 Addendum.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

For support, email admin@studyingking.local or open an issue in the repository.

## 📝 Changelog

### v0.1.0 (Current)
- Initial release
- Core subject and practice features
- Dynamic AI model fetching
- Settings management
- Database integration with Hive

---

Built with ❤️ by TomiWebPro
