import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../providers/bachat_gat_provider.dart';
import '../../models/group.dart';
import '../../models/report_models.dart';
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

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  late Stream<BachatGatGroup?> _groupStream;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final provider = Provider.of<BachatGatProvider>(context, listen: false);
    _groupStream = provider.watchGroup();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Monthly Register'),
            Tab(text: 'Pending Dues'),
            Tab(text: 'Loans Overview'),
          ],
        ),
      ),
      body: StreamBuilder<BachatGatGroup?>(
        stream: _groupStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final group = snapshot.data;
          if (group == null) return const Center(child: Text('Group not found'));

          return TabBarView(
            controller: _tabController,
            children: [
              // 1. Monthly Register Tab
              _buildMonthlyRegisterTab(provider, group, l10n),
              // 2. Pending Dues Tab
              _buildPendingDuesTab(provider, group, l10n),
              // 3. Loans Overview Tab
              _buildLoansOverviewTab(provider, group, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthlyRegisterTab(BachatGatProvider provider, BachatGatGroup group, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGenerateReportCard(provider, group, l10n),
          const SizedBox(height: 24),
          
          Text(l10n.collectionSummary.toUpperCase(), style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 16),
          _buildReportItem(context, l10n.totalSavings, group.totalSavings, Icons.savings_rounded, AppColors.success),
          _buildReportItem(context, 'Total Interest (2%)', group.totalInterestCollected, Icons.percent_rounded, AppColors.interest),
          _buildReportItem(context, 'Outstanding Principal', group.totalOutstandingLoans, Icons.history_rounded, AppColors.error),
          _buildReportItem(context, 'Available Group Balance', group.totalFund, Icons.account_balance_wallet_rounded, AppColors.primary),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MONTHLY REGISTER BREAKDOWN', style: Theme.of(context).textTheme.labelLarge),
              Text('${CalculationUtils.getMonthName(_selectedMonth)} $_selectedYear', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          
          FutureBuilder<GroupMonthlyReport>(
            future: provider.getGroupReport(group.name, _selectedMonth, _selectedYear),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
              }
              final report = snapshot.data;
              if (report == null || report.memberReports.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No collection records for this month')));
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: report.memberReports.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final mr = report.memberReports[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(mr.member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                              CalculationUtils.formatCurrency(mr.totalPaid),
                              style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.success, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Hafta: ${CalculationUtils.formatCurrency(mr.paidHafta)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            if (mr.interestAmount > 0)
                              Text('Interest (2%): ${CalculationUtils.formatCurrency(mr.interestAmount)}', style: const TextStyle(fontSize: 11, color: AppColors.interest)),
                            if (mr.principalRepaid > 0)
                              Text('Principal: ${CalculationUtils.formatCurrency(mr.principalRepaid)}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                          ],
                        ),
                        if (mr.closingPrincipal > 0) ...[
                          const SizedBox(height: 4),
                          Text('Pending Loan: ${CalculationUtils.formatCurrency(mr.closingPrincipal)}', style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPendingDuesTab(BachatGatProvider provider, BachatGatGroup group, AppLocalizations l10n) {
    return FutureBuilder<List<PendingMemberReport>>(
      future: provider.getPendingReport(month: _selectedMonth, year: _selectedYear),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final pendingList = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending Share Action Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pending Dues Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${pendingList.length} members have pending balance', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: pendingList.isEmpty ? null : () {
                        ShareService.sharePendingSummary(
                          pendingList: pendingList,
                          groupName: group.name,
                          month: _selectedMonth,
                          year: _selectedYear,
                          languageCode: l10n.localeName,
                        );
                      },
                      icon: const Icon(Icons.share_outlined, size: 14),
                      label: const Text('Share', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (pendingList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success),
                        SizedBox(height: 12),
                        Text('All collections up to date! No pending dues.', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final p = pendingList[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p.member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                CalculationUtils.formatCurrency(p.totalPending),
                                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.error, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (p.pendingHafta > 0)
                            Text('• Pending Hafta: ${CalculationUtils.formatCurrency(p.pendingHafta)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          if (p.pendingLoanPrincipal > 0)
                            Text('• Outstanding Loan Principal: ${CalculationUtils.formatCurrency(p.pendingLoanPrincipal)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          if (p.pendingInterest > 0)
                            Text('• Pending Interest (2%): ${CalculationUtils.formatCurrency(p.pendingInterest)}', style: const TextStyle(fontSize: 12, color: AppColors.interest)),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoansOverviewTab(BachatGatProvider provider, BachatGatGroup group, AppLocalizations l10n) {
    return FutureBuilder<List<LoanReportItem>>(
      future: provider.getLoanReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final loans = snapshot.data ?? [];

        if (loans.isEmpty) {
          return const Center(child: Text('No loans issued yet', style: TextStyle(color: AppColors.textMuted)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: loans.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = loans[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (item.loan.status.name == 'active' ? AppColors.error : AppColors.success).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.loan.status.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: item.loan.status.name == 'active' ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _smallStat('Original Loan', CalculationUtils.formatCurrency(item.loan.originalPrincipal)),
                      _smallStat('Principal Paid', CalculationUtils.formatCurrency(item.totalPrincipalPaid)),
                      _smallStat('Interest Paid (2%)', CalculationUtils.formatCurrency(item.totalInterestPaid)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Remaining: ${CalculationUtils.formatCurrency(item.currentPendingPrincipal)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error)),
                      Text('Repayments: ${item.repaymentCount}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _smallStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
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
