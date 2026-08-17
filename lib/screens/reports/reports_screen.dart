import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../providers/bachat_gat_provider.dart';
import '../../models/group.dart';
import '../../app/app_colors.dart';
import '../../core/utils/calculation_utils.dart';
import '../../services/pdf_service.dart';
import '../../services/share_service.dart';
import '../../l10n/app_localizations.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  late Stream<BachatGatGroup?> _groupStream;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BachatGatProvider>(context, listen: false);
    _groupStream = provider.watchGroup();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BachatGatProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.reports),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: StreamBuilder<BachatGatGroup?>(
        stream: _groupStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final group = snapshot.data;
          if (group == null) return const Center(child: Text('Group not found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGenerateReportCard(provider, group, l10n),
                const SizedBox(height: 32),
                
                Text(l10n.collectionSummary.toUpperCase(), style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 16),
                _buildReportItem(context, l10n.totalSavings, group.totalSavings, Icons.savings_rounded, AppColors.success),
                _buildReportItem(context, l10n.totalInterest, group.totalInterestCollected, Icons.percent_rounded, AppColors.interest),
                _buildReportItem(context, 'Outstanding Principal', group.totalOutstandingLoans, Icons.history_rounded, AppColors.error),
                _buildReportItem(context, 'Available Group Balance', group.totalFund, Icons.account_balance_wallet_rounded, AppColors.primary),
                
                const SizedBox(height: 32),
                Text('MONTHLY PERFORMANCE', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 16),
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 54, color: AppColors.primary.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      const Text('Savings Growth Chart', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Text('(Coming in next update)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildGenerateReportCard(BachatGatProvider provider, BachatGatGroup group, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.groupMonthlyReport,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    dropdownColor: AppColors.primary,
                    underline: const SizedBox(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(CalculationUtils.getMonthName(i + 1)))),
                    onChanged: (val) => setState(() => _selectedMonth = val!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    dropdownColor: AppColors.primary,
                    underline: const SizedBox(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: [2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                    onChanged: (val) => setState(() => _selectedYear = val!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateGroupReport(provider, group, l10n, isShare: false),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(l10n.view),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateGroupReport(provider, group, l10n, isShare: true),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(l10n.shareOnWhatsApp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    foregroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generateGroupReport(BachatGatProvider provider, BachatGatGroup group, AppLocalizations l10n, {required bool isShare}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final report = await provider.getGroupReport(group.name, _selectedMonth, _selectedYear);
      
      final labels = {
        'groupMonthlyReport': l10n.groupMonthlyReport,
        'totalMembers': l10n.totalMembers,
        'date': l10n.date,
        'collectionSummary': l10n.collectionSummary,
        'totalExpectedHafta': l10n.totalExpectedHafta,
        'totalHaftaCollected': l10n.totalHaftaCollected,
        'totalHaftaPending': l10n.totalHaftaPending,
        'loanSummary': l10n.loanSummary,
        'totalActiveLoans': l10n.totalActiveLoans,
        'totalPrincipalRepaid': l10n.totalPrincipalRepaid,
        'totalInterestCollected': l10n.totalInterestCollected,
        'totalOutstandingLoan': l10n.totalOutstandingLoan,
        'totalCollection': l10n.totalCollection,
        'memberWiseSummary': l10n.memberWiseSummary,
        'member': l10n.member,
        'hafta': l10n.hafta,
        'interest': l10n.interest,
        'principal': l10n.principal,
        'total': l10n.total,
        'pendingLoan': l10n.pendingLoan,
      };

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/BG_Group_Report_${_selectedMonth}_$_selectedYear.pdf';
      
      final file = await PdfService.generateGroupReport(
        report: report,
        labels: labels,
        filePath: filePath,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (isShare) {
        await ShareService.shareGroupReport(
          report: report,
          filePath: file.path,
          languageCode: l10n.localeName,
        );
      } else {
        await Printing.layoutPdf(onLayout: (format) async => file.readAsBytes());
      }
      
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildReportItem(BuildContext context, String label, double value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Text(
            CalculationUtils.formatCurrency(value),
            style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
