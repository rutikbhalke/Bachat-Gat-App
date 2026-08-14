import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'services/data_service.dart';
import 'models/member.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final dataService = DataService(prefs);
  
  // Seed data if first run
  if (dataService.getMembers().isEmpty) {
    await _seedData(dataService);
  }

  runApp(
    BachatGatApp(dataService: dataService),
  );
}

Future<void> _seedData(DataService ds) async {
  final m1 = Member(id: 'M1', name: 'Ramesh Pawar', phone: '9876543210', joinDate: DateTime(2026, 1, 1), monthlyInvestment: 1000);
  final m2 = Member(id: 'M2', name: 'Suresh Jadhav', phone: '9876543211', joinDate: DateTime(2026, 1, 1), monthlyInvestment: 1000);
  final m3 = Member(id: 'M3', name: 'Priya Shinde', phone: '9876543212', joinDate: DateTime(2026, 2, 1), monthlyInvestment: 1500);

  await ds.saveMembers([m1, m2, m3]);

  // January
  await ds.recordInvestment(member: m1, month: 1, year: 2026, amount: 1000);
  await ds.recordInvestment(member: m2, month: 1, year: 2026, amount: 1000);
  
  // February
  await ds.recordInvestment(member: m1, month: 2, year: 2026, amount: 1000);
  await ds.recordInvestment(member: m2, month: 2, year: 2026, amount: 1000);
  await ds.recordInvestment(member: m3, month: 2, year: 2026, amount: 1500);

  // Loan to Ramesh
  await ds.issueLoan(member: m1, amount: 50000, rate: 2.0, purpose: 'Home Repair');
  
  // Repayment
  final loan = ds.getLoans().first;
  await ds.recordRepayment(loan: loan, paymentAmount: 6000);
}