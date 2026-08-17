import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'services/firebase_service.dart';
import 'services/connectivity_test_service.dart';
import 'repositories/group_repository.dart';
import 'repositories/transaction_repository.dart';
import 'providers/locale_provider.dart';
import 'providers/bachat_gat_provider.dart';
import 'services/report_service.dart';

import 'services/business_flow_test_service.dart';

void main() async {
  // 1. FAST BINDING
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. PARALLEL INITIALIZATION
  late final SharedPreferences prefs;
  await Future.wait([
    () async {
      try {
        if (kIsWeb) {
          await Firebase.initializeApp(
            options: const FirebaseOptions(
              apiKey: "AIzaSyBjHEvpL4KK4n3NeCjgK12VoQIn0AZfvQA",
              appId: "1:1038306626235:web:7d054a950319db8fd3b79e",
              messagingSenderId: "1038306626235",
              projectId: "bachat-gat-app-9e38e",
              storageBucket: "bachat-gat-app-9e38e.firebasestorage.app",
            ),
          );
        } else {
          await Firebase.initializeApp();
        }
        debugPrint("FIREBASE CORE INITIALIZATION: SUCCESS");
        await ConnectivityTestService.runTest();
      } catch (e) {
        debugPrint("FIREBASE CORE INITIALIZATION: FAILED - $e");
      }
    }(),
    () async {
      prefs = await SharedPreferences.getInstance();
    }(),
  ]);
  
  // 3. SERVICE & REPO CREATION
  final firebaseService = FirebaseService();
  final groupRepo = GroupRepository(firebaseService);
  final txRepo = TransactionRepository(firebaseService);
  final reportService = ReportService(firebaseService);

  // 4. RUN FULL REAL BUSINESS DATA FLOW TEST
  BusinessFlowTestService.runFullBusinessFlowTest(
    firebaseService: firebaseService,
    groupRepo: groupRepo,
    txRepo: txRepo,
  );

  // 5. RUN APP IMMEDIATELY
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
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
