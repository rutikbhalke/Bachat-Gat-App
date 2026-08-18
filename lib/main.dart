import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'services/firebase_service.dart';
import 'repositories/group_repository.dart';
import 'repositories/transaction_repository.dart';
import 'providers/locale_provider.dart';
import 'providers/bachat_gat_provider.dart';
import 'services/report_service.dart';

void main() async {
  // 1. FAST BINDING
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. FIREBASE INITIALIZATION (BEFORE ANY FIREBASE SERVICE USAGE)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("FIREBASE CORE INITIALIZATION: SUCCESS");
  } catch (e) {
    debugPrint("FIREBASE CORE INITIALIZATION: FAILED - $e");
  }

  // 3. ASYNC PREFERENCES & SERVICE CREATION
  final prefs = await SharedPreferences.getInstance();
  
  final firebaseService = FirebaseService();
  final groupRepo = GroupRepository(firebaseService);
  final txRepo = TransactionRepository(firebaseService);
  final reportService = ReportService(firebaseService);

  // 4. RUN APP IMMEDIATELY
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider(prefs)),
        ChangeNotifierProvider(create: (_) => BachatGatProvider(groupRepo, txRepo, reportService)),
        Provider.value(value: firebaseService),
        Provider.value(value: groupRepo),
        Provider.value(value: txRepo),
        Provider.value(value: reportService),
        Provider.value(value: prefs),
      ],
      child: const BachatGatApp(),
    ),
  );
}
