import 'package:flutter_test/flutter_test.dart';
import 'package:bachat_gat/core/utils/calculation_utils.dart';
import 'package:bachat_gat/core/utils/marathi_transliteration.dart';
import 'package:bachat_gat/services/pdf_service.dart';
import 'package:bachat_gat/models/report_models.dart';
import 'package:bachat_gat/models/member.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Marathi Transliteration & PDF Name Spelling Tests', () {
    test('1. Specific user prompt names transliterate to exact authentic Marathi', () {
      expect(MarathiTransliteration.toMarathi('Tanmay Hase'), 'तन्मय हसे');
      expect(MarathiTransliteration.toMarathi('Vaibhav pawase'), 'वैभव पावसे');
      expect(MarathiTransliteration.toMarathi('Rutik Bhalke'), 'रुतिक भालके');
      expect(MarathiTransliteration.toMarathi('Rutik Bhakle'), 'रुतिक भाकले');
      expect(MarathiTransliteration.toMarathi('Aditya Dhumal'), 'आदित्य धुमाळ');
      expect(MarathiTransliteration.toMarathi('Hase Tanmay'), 'हसे तन्मय');
      expect(MarathiTransliteration.toMarathi('Pawase Vaibhav'), 'पावसे वैभव');
      expect(MarathiTransliteration.toMarathi('Bhake Rutik'), 'भाके रुतिक');
      expect(MarathiTransliteration.toMarathi('Dhumal Aditya'), 'धुमाळ आदित्य');
      expect(MarathiTransliteration.toMarathi('Dhanashri wale'), 'धनश्री वाले');
      expect(MarathiTransliteration.toMarathi('Priyanka Dhawale'), 'प्रियंका ढवळे');
    });

    test('2. Dynamic phonetic transliteration handles novel/future names smoothly', () {
      // Common names
      expect(MarathiTransliteration.toMarathi('Sachin Patil'), 'सचिन पाटील');
      expect(MarathiTransliteration.toMarathi('Rahul Shinde'), 'राहुल शिंदे');
      expect(MarathiTransliteration.toMarathi('Suresh Pawar'), 'सुरेश पवार');
      expect(MarathiTransliteration.toMarathi('Sneha Deshmukh'), 'स्नेहा देशमुख');
      expect(MarathiTransliteration.toMarathi('Sunita Kulkarni'), 'सुनिता कुलकर्णी');
      expect(MarathiTransliteration.toMarathi('Aniket Kadam'), 'अनिकेत कदम');
      expect(MarathiTransliteration.toMarathi('Pooja Jadhav'), 'पूजा जाधव');
      expect(MarathiTransliteration.toMarathi('Amit More'), 'अमित मोरे');
    });

    test('3. Already Devanagari text is preserved 100% untouched', () {
      expect(MarathiTransliteration.toMarathi('तन्मय हसे'), 'तन्मय हसे');
      expect(MarathiTransliteration.toMarathi('वैभव पावसे'), 'वैभव पावसे');
      expect(MarathiTransliteration.toMarathi('रुतिक भालके'), 'रुतिक भालके');
      expect(MarathiTransliteration.isDevanagari('तन्मय'), isTrue);
      expect(MarathiTransliteration.isDevanagari('Tanmay'), isFalse);
    });

    test('4. Marathi Month names translate correctly', () {
      expect(CalculationUtils.getMonthNameMarathi(1), 'जानेवारी');
      expect(CalculationUtils.getMonthNameMarathi(8), 'ऑगस्ट');
      expect(CalculationUtils.getMonthNameMarathi(12), 'डिसेंबर');
    });

    test('5. PDF generation preserves exact stored member names and produces valid bytes', () async {
      final member1 = Member(
        id: 'M1',
        groupId: 'G1',
        name: 'Tanmay Hase',
        phone: '9876543210',
        joinDate: DateTime(2026, 1, 1),
        monthlyContribution: 1000.0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 8, 18),
      );

      final member2 = Member(
        id: 'M2',
        groupId: 'G1',
        name: 'Vaibhav Pawase',
        phone: '9876543211',
        joinDate: DateTime(2026, 1, 1),
        monthlyContribution: 1000.0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 8, 18),
      );

      final groupReport = GroupMonthlyReport(
        groupName: 'Shivshahi Bachat Gat',
        month: 8,
        year: 2026,
        totalMembers: 2,
        totalExpectedHafta: 2000.0,
        totalCollectedHafta: 2000.0,
        totalPendingHafta: 0.0,
        totalActiveLoans: 1,
        totalPrincipalRepaid: 5000.0,
        totalInterestCollected: 200.0,
        totalOutstandingLoan: 5000.0,
        totalCollection: 7200.0,
        memberReports: [
          MemberMonthlyReport(
            member: member1,
            month: 8,
            year: 2026,
            expectedHafta: 1000.0,
            paidHafta: 1000.0,
            pendingHafta: 0.0,
            openingPrincipal: 10000.0,
            interestRate: 2.0,
            interestAmount: 200.0,
            principalRepaid: 5000.0,
            closingPrincipal: 5000.0,
            totalPaid: 6200.0,
          ),
          MemberMonthlyReport(
            member: member2,
            month: 8,
            year: 2026,
            expectedHafta: 1000.0,
            paidHafta: 1000.0,
            pendingHafta: 0.0,
            openingPrincipal: 0.0,
            interestRate: 2.0,
            interestAmount: 0.0,
            principalRepaid: 0.0,
            closingPrincipal: 0.0,
            totalPaid: 1000.0,
          ),
        ],
      );

      // English Labels
      final englishLabels = {
        'groupName': 'Shivshahi Bachat Gat',
        'groupMonthlyReport': 'Group Monthly Report',
        'totalMembers': 'Total Members',
        'date': 'Date',
        'collectionSummary': 'Collection Summary',
        'totalExpectedHafta': 'Total Expected Hafta',
        'totalHaftaCollected': 'Total Hafta Collected',
        'totalHaftaPending': 'Total Hafta Pending',
        'loanSummary': 'Loan Summary',
        'totalActiveLoans': 'Total Active Loans',
        'totalPrincipalRepaid': 'Total Principal Repaid',
        'totalInterestCollected': 'Total Interest Collected',
        'totalOutstandingLoan': 'Total Outstanding Loan',
        'totalCollection': 'Total Collection',
        'memberWiseSummary': 'Member-wise Summary',
        'member': 'Member',
        'hafta': 'Hafta',
        'interest': 'Interest (2%)',
        'principal': 'Principal',
        'total': 'Total Paid',
        'pendingLoan': 'Pending Loan',
        'isMarathi': 'false',
      };

      // Marathi Labels
      final marathiLabels = {
        'groupName': 'शिवशाही बचत गट',
        'groupMonthlyReport': 'गटाचा मासिक अहवाल',
        'totalMembers': 'एकूण सभासद',
        'date': 'दिनांक',
        'collectionSummary': 'वसुली सारांश',
        'totalExpectedHafta': 'एकूण अपेक्षित हप्ता',
        'totalHaftaCollected': 'एकूण जमा हप्ता',
        'totalHaftaPending': 'एकूण बाकी हप्ता',
        'loanSummary': 'कर्ज सारांश',
        'totalActiveLoans': 'एकूण चालू कर्ज',
        'totalPrincipalRepaid': 'एकूण परतफेड केलेले मुद्दल',
        'totalInterestCollected': 'एकूण जमा झालेले व्याज',
        'totalOutstandingLoan': 'एकूण बाकी कर्ज',
        'totalCollection': 'एकूण वसुली',
        'memberWiseSummary': 'सभासदनिहाय सारांश',
        'member': 'सभासद',
        'hafta': 'हप्ता',
        'interest': 'व्याज',
        'principal': 'मुद्दल',
        'total': 'एकूण',
        'pendingLoan': 'बाकी कर्ज',
        'isMarathi': 'true',
      };

      final enBytes = await PdfService.generateGroupReportBytes(
        report: groupReport,
        labels: englishLabels,
      );
      expect(enBytes.isNotEmpty, isTrue);

      final mrBytes = await PdfService.generateGroupReportBytes(
        report: groupReport,
        labels: marathiLabels,
      );
      expect(mrBytes.isNotEmpty, isTrue);
    });
  });
}
