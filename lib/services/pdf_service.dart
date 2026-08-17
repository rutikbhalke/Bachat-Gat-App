import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/report_models.dart';
import '../core/utils/calculation_utils.dart';

class PdfService {
  static Future<pw.Font> getFont() async {
    // For Marathi support
    return await PdfGoogleFonts.notoSansDevanagariRegular();
  }

  static Future<pw.Font> getBoldFont() async {
    return await PdfGoogleFonts.notoSansDevanagariBold();
  }

  static Future<File> generateMemberReceipt({
    required MemberMonthlyReport report,
    required Map<String, String> labels,
    required String filePath,
  }) async {
    final pdf = pw.Document();
    final font = await getFont();
    final boldFont = await getBoldFont();

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
                    pw.Text('BG-${report.year}-${report.month.toString().padLeft(2, '0')}-${report.member.id.substring(0, 4)}', style: pw.TextStyle(fontSize: 10)),
                    pw.Text(labels['groupName'] ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.Text(CalculationUtils.formatShortDate(DateTime.now()), style: pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text(labels['monthlyReceipt'] ?? 'Monthly Receipt', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('${labels['member']}: ${report.member.name}'),
                      pw.Text('${labels['phone']}: ${report.member.phone}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('${labels['month']}: ${CalculationUtils.getMonthName(report.month)} ${report.year}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              
              _buildSectionTitle(labels['monthlyContribution'] ?? 'Monthly Contribution', boldFont),
              _buildRow(labels['regularHafta'] ?? 'Regular Hafta', report.expectedHafta),
              _buildRow(labels['amountPaid'] ?? 'Amount Paid', report.paidHafta),
              _buildRow(labels['pending'] ?? 'Pending', report.pendingHafta, isError: report.pendingHafta > 0),
              
              pw.SizedBox(height: 20),
              
              _buildSectionTitle(labels['loan'] ?? 'Loan', boldFont),
              _buildRow(labels['openingLoan'] ?? 'Opening Loan', report.openingPrincipal),
              _buildRow(labels['interestRate'] ?? 'Interest Rate', report.interestRate, isPercent: true),
              _buildRow(labels['monthlyInterest'] ?? 'Monthly Interest', report.interestAmount),
              _buildRow(labels['loanRepaid'] ?? 'Loan Principal Repaid', report.principalRepaid),
              _buildRow(labels['closingLoan'] ?? 'Closing Pending Loan', report.closingPrincipal),
              
              pw.SizedBox(height: 20),
              pw.Divider(),
              
              _buildSectionTitle(labels['total'] ?? 'Total', boldFont),
              _buildRow(labels['totalPaid'] ?? 'Total Paid', report.totalPaid, isBold: true),
              
              pw.Spacer(),
              pw.Center(
                child: pw.Text('Thank you for your contribution!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> generateGroupReport({
    required GroupMonthlyReport report,
    required Map<String, String> labels,
    required String filePath,
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
            pw.Text(report.groupName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('${CalculationUtils.getMonthName(report.month)} ${report.year}'),
          ],
        ),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 20),
            pw.Center(child: pw.Text(labels['groupMonthlyReport'] ?? 'Group Monthly Report', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
            pw.SizedBox(height: 20),
            
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${labels['totalMembers']}: ${report.totalMembers}'),
                pw.Text('${labels['date']}: ${CalculationUtils.formatShortDate(DateTime.now())}'),
              ],
            ),
            
            pw.SizedBox(height: 20),
            _buildSectionTitle(labels['collectionSummary'] ?? 'Collection Summary', boldFont),
            _buildRow(labels['totalExpectedHafta'] ?? 'Total Expected Hafta', report.totalExpectedHafta),
            _buildRow(labels['totalHaftaCollected'] ?? 'Total Hafta Collected', report.totalCollectedHafta),
            _buildRow(labels['totalHaftaPending'] ?? 'Total Hafta Pending', report.totalPendingHafta, isError: report.totalPendingHafta > 0),
            
            pw.SizedBox(height: 20),
            _buildSectionTitle(labels['loanSummary'] ?? 'Loan Summary', boldFont),
            _buildRow(labels['totalActiveLoans'] ?? 'Total Active Loans', report.totalActiveLoans),
            _buildRow(labels['totalPrincipalRepaid'] ?? 'Total Principal Repaid', report.totalPrincipalRepaid),
            _buildRow(labels['totalInterestCollected'] ?? 'Total Interest Collected', report.totalInterestCollected),
            _buildRow(labels['totalOutstandingLoan'] ?? 'Total Outstanding Loan', report.totalOutstandingLoan),
            
            pw.SizedBox(height: 20),
            _buildSectionTitle(labels['totalCollection'] ?? 'Total Collection', boldFont),
            _buildRow(labels['totalCollection'] ?? 'Total Collection', report.totalCollection, isBold: true),
            
            pw.SizedBox(height: 30),
            _buildSectionTitle(labels['memberWiseSummary'] ?? 'Member-wise Summary', boldFont),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _cell(labels['member'] ?? 'Member', isBold: true),
                    _cell(labels['hafta'] ?? 'Hafta', isBold: true),
                    _cell(labels['interest'] ?? 'Interest', isBold: true),
                    _cell(labels['principal'] ?? 'Principal', isBold: true),
                    _cell(labels['total'] ?? 'Total', isBold: true),
                    _cell(labels['pendingLoan'] ?? 'Pending Loan', isBold: true),
                  ],
                ),
                ...report.memberReports.map((r) => pw.TableRow(
                  children: [
                    _cell(r.member.name),
                    _cell(CalculationUtils.formatCurrency(r.paidHafta)),
                    _cell(CalculationUtils.formatCurrency(r.interestAmount)),
                    _cell(CalculationUtils.formatCurrency(r.principalRepaid)),
                    _cell(CalculationUtils.formatCurrency(r.totalPaid)),
                    _cell(CalculationUtils.formatCurrency(r.closingPrincipal)),
                  ],
                )),
              ],
            ),
          ];
        },
      ),
    );

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return file;
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
