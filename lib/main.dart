import 'package:flutter/material.dart';
import 'screen/BachatDashboardScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BachatGatApp());
}

class BachatGatApp extends StatelessWidget {
  const BachatGatApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bachat Gat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF1B5E20),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          secondary: const Color(0xFFFFD54F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        fontFamily: 'Roboto',
      ),
      home: BachatDashboardScreen(),
    );
  }
}
