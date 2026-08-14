import 'package:flutter/material.dart';
import 'app_theme.dart';
import '../services/data_service.dart';
import '../screens/main_navigation_screen.dart';

class BachatGatApp extends StatelessWidget {
  final DataService dataService;

  const BachatGatApp({
    super.key,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bachat Gat',
      theme: AppTheme.lightTheme,
      home: MainNavigationScreen(dataService: dataService),
    );
  }
}