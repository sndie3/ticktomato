[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

# Study Buddy
A productivity and study companion app built with Flutter.

## Features

- **Pomodoro Timer**: Stay focused and productive with a built-in Pomodoro timer. The timer continues running even if you leave the screen, so you never lose your progress. Includes a compact widget and a full timer screen.
- **Study with AI**: Ask any question or request code generation using Cohere AI. Get instant explanations, study help, or coding assistance.
- **Quiz**: Test your knowledge by taking quizzes in various categories. Track your scores and progress.
- **User History & Analytics**: View your quiz history, performance over time, category statistics, and score progress charts.
- **Recent Quizzes**: See a list of your most recent quiz attempts with scores and categories.
- **Authentication**: Secure login and registration with Supabase.
- **Modern UI**: Clean, responsive, and user-friendly interface with beautiful white login/register forms.
- **Supabase Integration**: All user data, authentication, and quiz scores are securely managed in the cloud using Supabase.
- **Cloud Sync**: Your progress and history are always available across devices.

## Getting Started

1. Clone the repository.
2. Add your Supabase and Cohere API keys in `lib/main.dart`.
3. Add your logo image at `assets/icon/logo.JPG` and update `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/icon/logo.JPG
   ```
4. Run `flutter pub get`.
5. Run the app on your device or emulator.

---

Feel free to ask for more details or a full setup guide!

## 👨‍💻 Developer
**Sandie**

---


## 🛠️ Built With
- **Dart** & **Flutter** (cross-platform mobile framework)
- **Supabase** (cloud database and authentication)

---

## 🔗 APIs Used
- [Cohere API](https://cohere.com/) — for AI-powered study suggestions and chat
- [Open Trivia DB API](https://opentdb.com/) — for quiz questions and categories

---

## 🗄️ Database
- **Supabase** is used for cloud storage of users, quiz scores, and user history.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
