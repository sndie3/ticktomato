import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class SessionGuard extends StatelessWidget {
  final Widget child;
  const SessionGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // Not logged in, redirect to login
      return const LoginScreen();
    }
    return child;
  }
}
