import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/cohere_service.dart';
import 'services/quiz_service.dart';
import 'services/supabase_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService().initialize(
    supabaseUrl: AppConfig.supabaseUrl,
    supabaseAnonKey: AppConfig.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<CohereService>(
          create: (_) => CohereService(
            apiKey: AppConfig.cohereApiKey,
          ),
        ),
        Provider<QuizService>(create: (_) => QuizService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudyBuddy',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {}); // Rebuild on auth state change
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const LoginScreen();
    } else {
      return const HomeScreen();
    }
  }
}
