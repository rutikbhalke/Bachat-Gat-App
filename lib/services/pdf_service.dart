import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/report_models.dart';
import '../models/member.dart';
import '../core/utils/calculation_utils.dart';
import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_mr.dart';
import '../l10n/app_localizations_en.dart';

class PdfService {
  static Future<pw.Font> getFont() async {
    return await PdfGoogleFonts.notoSansDevanagariRegular();
  }

  static Future<pw.Font> getBoldFont() async {
    return await PdfGoogleFonts.notoSansDevanagariBold();
  }

  /// Helper to determine if the report is in Marathi
  static bool _isMarathi(Map<String, String> labels) {
    return labels['isMarathi'] == 'true' ||
        labels['member'] == 'सभासद' ||
        (labels['groupMonthlyReport'] != null && labels['groupMonthlyReport']!.contains('गट'));
  }

  /// Direct centralized localization provider
  static AppLocalizations _getL10n(Map<String, String> labels) {
    if (_isMarathi(labels)) {
      return AppLocalizationsMr();
    }
    return AppLocalizationsEn();
  }

  /// Generates Member Monthly Receipt PDF bytes directly in-memory.
  /// Works across all platforms (Android, iOS, Web, Desktop).
  static Future<Uint8List> generateMemberReceiptBytes({
    required MemberMonthlyReport report,
    required Map<String, String> labels,
  }) async {
    final pdf = pw.Document();
    final font = await getFont();
    final boldFont = await getBoldFont();
    final isMarathi = _isMarathi(labels);
    final l10n = _getL10n(labels);
    final memberDisplayName = report.member.name;

    final receiptTitle = l10n.monthlyReceipt;
    final memberLabel = l10n.member;
    final phoneLabel = l10n.phone;
    final monthLabel = l10n.month;
    final monthYearText = isMarathi
        ? '${CalculationUtils.getMonthNameMarathi(report.month)} ${report.year}'
        : '${CalculationUtils.getMonthName(report.month)} ${report.year}';

    final contributionTitle = l10n.monthlyContribution;
    final regularHaftaLabel = l10n.regularHafta;
    final amountPaidLabel = l10n.amountPaid;
    final pendingHaftaLabel = l10n.totalHaftaPending;

    final loanTitle = l10n.loan;
    final openingLoanLabel = l10n.openingLoan;
    final interestRateLabel = l10n.interestRate;
    final monthlyInterestLabel = l10n.monthlyInterest;
    final loanRepaidLabel = l10n.loanRepaid;
    final closingLoanLabel = l10n.closingLoan;

    final totalTitle = l10n.total;
    final totalPaidLabel = l10n.totalPaid;
    final footerText = isMarathi ? 'तुमच्या सहभागाबद्दल धन्यवाद!' : 'Thank you for your contribution!';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('BG-${report.year}-${report.month.toString().padLeft(2, '0')}-${report.member.id.length >= 4 ? report.member.id.substring(0, 4) : report.member.id}', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(labels['groupName'] ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.Text(CalculationUtils.formatShortDate(DateTime.now()), style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text(receiptTitle, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('$memberLabel: $memberDisplayName'),
                      pw.Text('$phoneLabel: ${report.member.phone}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('$monthLabel: $monthYearText'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              
              _buildSectionTitle(contributionTitle, boldFont),
              _buildRow(regularHaftaLabel, report.expectedHafta),
              _buildRow(amountPaidLabel, report.paidHafta),
              _buildRow(pendingHaftaLabel, report.pendingHafta, isError: report.pendingHafta > 0),
              
              pw.SizedBox(height: 20),
              
              _buildSectionTitle(loanTitle, boldFont),
              _buildRow(openingLoanLabel, report.openingPrincipal),
              _buildRow(interestRateLabel, report.interestRate, isPercent: true),
              _buildRow(monthlyInterestLabel, report.interestAmount),
              _buildRow(loanRepaidLabel, report.principalRepaid),
              _buildRow(closingLoanLabel, report.closingPrincipal),
              
              pw.SizedBox(height: 20),
              pw.Divider(),
              
              _buildSectionTitle(totalTitle, boldFont),
              _buildRow(totalPaidLabel, report.totalPaid, isBold: true),
              
              pw.Spacer(),
              pw.Center(
                child: pw.Text(footerText, style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates Group Monthly Report PDF bytes directly in-memory.
  /// Works across all platforms (Android, iOS, Web, Desktop).
  static Future<Uint8List> generateGroupReportBytes({
    required GroupMonthlyReport report,
    required Map<String, String> labels,
  }) async {
    final pdf = pw.Document();
    final font = await getFont();
    final boldFont = await getBoldFont();
    final isMarathi = _isMarathi(labels);
    final l10n = _getL10n(labels);

    // Precise terminology directly sourced from AppLocalizations
    final titleText = l10n.groupMonthlyReport;
    final totalMembersLabel = l10n.totalMembers;
    final dateLabel = l10n.date;
    final monthYearText = isMarathi
        ? '${CalculationUtils.getMonthNameMarathi(report.month)} ${report.year}'
        : '${CalculationUtils.getMonthName(report.month)} ${report.year}';

    final collectionSummaryTitle = l10n.collectionSummary;
    final totalExpectedHaftaLabel = l10n.totalExpectedHafta;
    final totalHaftaCollectedLabel = l10n.totalHaftaCollected;
    final totalHaftaPendingLabel = l10n.totalHaftaPending;

    final loanSummaryTitle = l10n.loanSummary;
    final totalActiveLoansLabel = l10n.totalActiveLoans;
    final totalPrincipalRepaidLabel = l10n.totalPrincipalRepaid;
    final totalInterestCollectedLabel = l10n.totalInterestCollected;
    final totalOutstandingLoanLabel = l10n.totalOutstandingLoan;

    final totalCollectionLabel = l10n.totalCollection;

    final memberWiseSummaryTitle = l10n.memberWiseSummary;

    // Table Column Headers
    final tableColMember = l10n.member;
    final tableColHafta = l10n.hafta;
    final tableColInterest = l10n.interest;
    final tableColPrincipal = l10n.principal;
    final tableColTotal = l10n.total;
    final tableColOutstanding = l10n.pendingLoan;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        header: (pw.Context context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(report.groupName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text(monthYearText),
          ],
        ),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),
            pw.Center(child: pw.Text(titleText, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
            pw.SizedBox(height: 20),
            
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('$totalMembersLabel: ${report.totalMembers}'),
                pw.Text('$dateLabel: ${CalculationUtils.formatShortDate(DateTime.now())}'),
              ],
            ),
            
            pw.SizedBox(height: 20),
            _buildSectionTitle(collectionSummaryTitle, boldFont),
            _buildRow(totalExpectedHaftaLabel, report.totalExpectedHafta),
            _buildRow(totalHaftaCollectedLabel, report.totalCollectedHafta),
            _buildRow(totalHaftaPendingLabel, report.totalPendingHafta, isError: report.totalPendingHafta > 0),
            
            pw.SizedBox(height: 20),
            _buildSectionTitle(loanSummaryTitle, boldFont),
            _buildRow(totalActiveLoansLabel, report.totalActiveLoans),
            _buildRow(totalPrincipalRepaidLabel, report.totalPrincipalRepaid),
            _buildRow(totalInterestCollectedLabel, report.totalInterestCollected),
            _buildRow(totalOutstandingLoanLabel, report.totalOutstandingLoan),
            
            pw.SizedBox(height: 20),
            _buildRow(totalCollectionLabel, report.totalCollection, isBold: true),
            
            pw.SizedBox(height: 30),
            _buildSectionTitle(memberWiseSummaryTitle, boldFont),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cell(tableColMember, isBold: true),
                    _cell(tableColHafta, isBold: true),
                    _cell(tableColInterest, isBold: true),
                    _cell(tableColPrincipal, isBold: true),
                    _cell(tableColTotal, isBold: true),
                    _cell(tableColOutstanding, isBold: true),
                  ],
                ),
                ...report.memberReports.map((r) {
                  return pw.TableRow(
                    children: [
                      _cell(r.member.name),
                      _cell(CalculationUtils.formatCurrency(r.paidHafta)),
                      _cell(CalculationUtils.formatCurrency(r.interestAmount)),
                      _cell(CalculationUtils.formatCurrency(r.principalRepaid)),
                      _cell(CalculationUtils.formatCurrency(r.totalPaid)),
                      _cell(CalculationUtils.formatCurrency(r.closingPrincipal)),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Generates Member Ledger PDF bytes directly in-memory.
  /// Works across all platforms (Android, iOS, Web, Desktop).
  static Future<Uint8List> generateMemberLedgerBytes({
    required Member member,
    required List<MemberLedgerEntry> entries,
    required String groupName,
  }) async {
    final pdf = pw.Document();
    final font = await getFont();
    final boldFont = await getBoldFont();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        header: (pw.Context context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(groupName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Member Ledger - ${member.name}'),
          ],
        ),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),
            pw.Center(child: pw.Text('Member Statement & Ledger', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
            pw.SizedBox(height: 15),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Member: ${member.name} (${member.phone})'),
                pw.Text('Joined: ${CalculationUtils.formatShortDate(member.joinDate)}'),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cell('Date', isBold: true),
                    _cell('Description', isBold: true),
                    _cell('Debit (₹)', isBold: true),
                    _cell('Credit (₹)', isBold: true),
                    _cell('Balance (₹)', isBold: true),
                  ],
                ),
                ...entries.map((e) => pw.TableRow(
                  children: [
                    _cell(CalculationUtils.formatShortDate(e.date)),
                    _cell(e.description),
                    _cell(e.debit > 0 ? CalculationUtils.formatCurrency(e.debit) : '-'),
                    _cell(e.credit > 0 ? CalculationUtils.formatCurrency(e.credit) : '-'),
                    _cell(CalculationUtils.formatCurrency(e.balance)),
                  ],
                )),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSectionTitle(String title, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 12, decoration: pw.TextDecoration.underline)),
    );
  }

  static pw.Widget _buildRow(String label, double value, {bool isPercent = false, bool isBold = false, bool isError = false}) {
    final style = pw.TextStyle(
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: isError ? PdfColors.red : PdfColors.black,
    );
    
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(
            isPercent ? '${value.toStringAsFixed(1)}%' : CalculationUtils.formatCurrency(value),
            style: style,
          ),
        ],
      ),
    );
  }

  static pw.Widget _cell(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
}
