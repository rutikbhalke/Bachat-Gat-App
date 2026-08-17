import 'package:flutter/material.dart';

void main() {
  runApp(const DiagnosticApp());
}

class DiagnosticApp extends StatelessWidget {
  const DiagnosticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const DiagnosticScreen(),
    );
  }
}

class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostic Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('If this counter increments immediately on tap, the emulator is fine.'),
            const SizedBox(height: 20),
            Text('Counter: $_counter', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                debugPrint('BUTTON TAPPED');
                setState(() {
                  _counter++;
                });
              },
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
