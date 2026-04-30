import 'package:auth_app/screens/login_page.dart';
import 'package:auth_app/screens/splash_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Auth Example',
        home: SplashPage(),
      ),
    );
  }
}
