import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bachat_gat/models/member.dart';
import 'package:bachat_gat/widgets/common/searchable_member_picker.dart';
import 'package:bachat_gat/l10n/app_localizations.dart';

void main() {
  final memberAkshay1 = Member(
    id: 'M_1',
    groupId: 'g_1',
    name: 'अक्षय थोरात 1',
    phone: '9876543210',
    joinDate: DateTime(2026, 1, 1),
    shares: 1,
    monthlyContributionPerShare: 1000.0,
    monthlyContribution: 1000.0,
    status: MemberStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final memberAkshay2 = Member(
    id: 'M_2',
    groupId: 'g_1',
    name: 'अक्षय थोरात 2',
    phone: '9876543211',
    joinDate: DateTime(2026, 1, 1),
    shares: 1,
    monthlyContributionPerShare: 1000.0,
    monthlyContribution: 1000.0,
    status: MemberStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final memberBalasaheb = Member(
    id: 'M_3',
    groupId: 'g_1',
    name: 'बाळासाहेब जाधव',
    phone: '9123456789',
    joinDate: DateTime(2026, 1, 1),
    shares: 1,
    monthlyContributionPerShare: 1000.0,
    monthlyContribution: 1000.0,
    status: MemberStatus.active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final pendingMembers = [memberAkshay1, memberAkshay2, memberBalasaheb];
  final pendingAmounts = {'M_1': 1000.0, 'M_2': 1000.0, 'M_3': 1000.0};

  Widget buildTestWidget({Member? initiallySelected}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('mr'),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => SearchableMemberPicker.show(
              context: context,
              pendingMembers: pendingMembers,
              pendingAmounts: pendingAmounts,
              initiallySelected: initiallySelected,
            ),
            child: const Text('Open Picker'),
          ),
        ),
      ),
    );
  }

  testWidgets('SearchableMemberPicker displays all pending members with ₹1,000 badge and filters on search', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Open dialog
    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Verify dialog elements
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('अक्षय थोरात 1'), findsOneWidget);
    expect(find.text('अक्षय थोरात 2'), findsOneWidget);
    expect(find.text('बाळासाहेब जाधव'), findsOneWidget);
    expect(find.text('₹1000'), findsNWidgets(3));

    // Type "अक्षय" in search bar
    await tester.enterText(find.byType(TextField), 'अक्षय');
    await tester.pumpAndSettle();

    // Verify filtered results
    expect(find.text('अक्षय थोरात 1'), findsOneWidget);
    expect(find.text('अक्षय थोरात 2'), findsOneWidget);
    expect(find.text('बाळासाहेब जाधव'), findsNothing);

    // Type non-matching query
    await tester.enterText(find.byType(TextField), 'संदीप');
    await tester.pumpAndSettle();

    expect(find.text('सभासद सापडला नाही'), findsOneWidget);
    expect(find.text('अक्षय थोरात 1'), findsNothing);

    // Search by phone number
    await tester.enterText(find.byType(TextField), '9123456789');
    await tester.pumpAndSettle();

    expect(find.text('बाळासाहेब जाधव'), findsOneWidget);
    expect(find.text('अक्षय थोरात 1'), findsNothing);

    // Tap member to select
    await tester.tap(find.text('बाळासाहेब जाधव'));
    await tester.pumpAndSettle();

    // Dialog dismissed
    expect(find.byType(AlertDialog), findsNothing);
  });
}
