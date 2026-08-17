import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import '../providers/locale_provider.dart';
import '../screens/main_navigation_screen.dart';

class BachatGatApp extends StatelessWidget {
  const BachatGatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bachat Gat',
      theme: AppTheme.lightTheme,
      locale: localeProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return ColoredBox(
          color: const Color(0xFFEFF2F6),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 330),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 30,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRect(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
      home: const MainNavigationScreen(),
    );
  }
}
