import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  // Cached futures for lazy on-demand tab loading
  Future<GroupMonthlyReport>? _monthlyReportFuture;
  Future<List<PendingMemberReport>>? _pendingReportFuture;
  Future<List<LoanReportItem>>? _loansReportFuture;

  String _groupName = 'Shivshahi Bachat Gat';

  @override
  void initState() {
    super.initState();
    debugPrint('[REPORT] SCREEN INIT: month=$_selectedMonth, year=$_selectedYear');
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    final provider = Provider.of<BachatGatProvider>(context, listen: false);
    debugPrint('[REPORT] GROUP ID = ${provider.groupId}');
    debugPrint('[REPORT] MONTH/YEAR = $_selectedMonth/$_selectedYear');
    _groupStream = provider.watchGroup();

    // Immediately start loading active tab (Tab 0: Monthly Register)
    _monthlyReportFuture = provider.getGroupReport(
      _groupName,
      _selectedMonth,
      _selectedYear,
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    debugPrint('[REPORT] TAB CHANGED TO: ${_tabController.index}');
    _ensureTabLoaded(_tabController.index);
  }

  void _ensureTabLoaded(int tabIndex, {bool forceRefresh = false}) {
    final provider = Provider.of<BachatGatProvider>(context, listen: false);
    setState(() {
      if (tabIndex == 0) {
        if (_monthlyReportFuture == null || forceRefresh) {
          debugPrint('[REPORT] Initiating Monthly Register tab load (forceRefresh=$forceRefresh)');
          _monthlyReportFuture = provider.getGroupReport(
            _groupName,
            _selectedMonth,
            _selectedYear,
            forceRefresh: forceRefresh,
          );
        }
      } else if (tabIndex == 1) {
        if (_pendingReportFuture == null || forceRefresh) {
          debugPrint('[REPORT] Initiating Pending Dues tab load (forceRefresh=$forceRefresh)');
          _pendingReportFuture = provider.getPendingReport(
            month: _selectedMonth,
            year: _selectedYear,
            forceRefresh: forceRefresh,
          );
        }
      } else if (tabIndex == 2) {
        if (_loansReportFuture == null || forceRefresh) {
          debugPrint('[REPORT] Initiating Loans Overview tab load (forceRefresh=$forceRefresh)');
          _loansReportFuture = provider.getLoanReport(forceRefresh: forceRefresh);
        }
      }
    });
  }

  void _onDateChanged(int newMonth, int newYear) {
    debugPrint('[REPORT] DATE CHANGED: month=$newMonth, year=$newYear');
    setState(() {
      _selectedMonth = newMonth;
      _selectedYear = newYear;
      // Invalidate month-dependent futures
      _monthlyReportFuture = null;
      _pendingReportFuture = null;
    });
    _ensureTabLoaded(_tabController.index, forceRefresh: true);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refreshReport,
            onPressed: () {
              debugPrint('[REPORT] Manual Refresh Clicked');
              provider.invalidateReports();
              _ensureTabLoaded(_tabController.index, forceRefresh: true);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: l10n.monthlyRegister),
            Tab(text: l10n.pendingDues),
            Tab(text: l10n.loansOverview),
          ],
        ),
      ),
      body: StreamBuilder<BachatGatGroup?>(
        stream: _groupStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint('[REPORT ERROR] Group stream encountered error: ${snapshot.error}');
          }

          final group = snapshot.data ??
              BachatGatGroup(
                id: provider.groupId,
                name: _groupName,
                managerId: 'manager_001',
                monthlyTarget: 6000.0,
                monthlyContributionAmount: 1000.0,
                totalFund: 0.0,
                totalSavings: 0.0,
                totalOutstandingLoans: 0.0,
                totalInterestCollected: 0.0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

          if (snapshot.hasData && snapshot.data != null && snapshot.data!.name != _groupName) {
            _groupName = snapshot.data!.name;
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // 1. Monthly Register Tab (loaded initially)
              _buildMonthlyRegisterTab(provider, group, l10n),
              // 2. Pending Dues Tab (loaded on-demand when selected)
              _buildPendingDuesTab(provider, group, l10n),
              // 3. Loans Overview Tab (loaded on-demand when selected)
              _buildLoansOverviewTab(provider, group, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMonthlyRegisterTab(BachatGatProvider provider, BachatGatGroup group, AppLocalizations l10n) {
    _monthlyReportFuture ??= provider.getGroupReport(
      group.name,
      _selectedMonth,
      _selectedYear,
    );

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
          _buildReportItem(context, l10n.totalInterest2Percent, group.totalInterestCollected, Icons.percent_rounded, AppColors.interest),
          _buildReportItem(context, l10n.outstandingPrincipal, group.totalOutstandingLoans, Icons.history_rounded, AppColors.error),
          _buildReportItem(context, l10n.availableGroupBalance, CalculationUtils.calculateAvailableCash(group.totalFund), Icons.account_balance_wallet_rounded, AppColors.primary),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.monthlyRegisterBreakdown.toUpperCase(), style: Theme.of(context).textTheme.labelLarge),
              Text(
                '${l10n.localeName == 'mr' ? CalculationUtils.getMonthNameMarathi(_selectedMonth) : CalculationUtils.getMonthName(_selectedMonth)} $_selectedYear',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          FutureBuilder<GroupMonthlyReport>(
            future: _monthlyReportFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()));
              }

              if (snapshot.hasError) {
                debugPrint('[REPORT ERROR] Monthly Register UI error: ${snapshot.error}');
                return _buildErrorCard('Failed to load monthly register: ${snapshot.error}', () {
                  _ensureTabLoaded(0, forceRefresh: true);
                });
              }

              final report = snapshot.data;
              if (report == null || report.memberReports.isEmpty) {
                return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text(l10n.noCollectionRecordsForMonth)));
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
                            Text('${l10n.hafta}: ${CalculationUtils.formatCurrency(mr.paidHafta)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            if (mr.interestAmount > 0)
                              Text('${l10n.interest} (2%): ${CalculationUtils.formatCurrency(mr.interestAmount)}', style: const TextStyle(fontSize: 11, color: AppColors.interest)),
                            if (mr.principalRepaid > 0)
                              Text('${l10n.principal}: ${CalculationUtils.formatCurrency(mr.principalRepaid)}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                          ],
                        ),
                        if (mr.closingPrincipal > 0) ...[
                          const SizedBox(height: 4),
                          Text('${l10n.pendingLoan}: ${CalculationUtils.formatCurrency(mr.closingPrincipal)}', style: const TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w600)),
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
    _pendingReportFuture ??= provider.getPendingReport(month: _selectedMonth, year: _selectedYear);

    return FutureBuilder<List<PendingMemberReport>>(
      future: _pendingReportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('[REPORT ERROR] Pending Dues UI error: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildErrorCard('Failed to load pending dues: ${snapshot.error}', () {
                _ensureTabLoaded(1, forceRefresh: true);
              }),
            ),
          );
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
                          Text(l10n.pendingDuesSummary, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('${pendingList.length} ${l10n.membersPendingBalance}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: pendingList.isEmpty
                          ? null
                          : () {
                              ShareService.sharePendingSummary(
                                pendingList: pendingList,
                                groupName: group.name,
                                month: _selectedMonth,
                                year: _selectedYear,
                                languageCode: l10n.localeName,
                              );
                            },
                      icon: const Icon(Icons.share_outlined, size: 14),
                      label: Text(l10n.share, style: const TextStyle(fontSize: 12)),
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
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success),
                        const SizedBox(height: 12),
                        Text(l10n.allCollectionsUpToDate, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
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
                            Text('• ${l10n.pendingHafta}: ${CalculationUtils.formatCurrency(p.pendingHafta)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          if (p.pendingLoanPrincipal > 0)
                            Text('• ${l10n.outstandingLoanPrincipal}: ${CalculationUtils.formatCurrency(p.pendingLoanPrincipal)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          if (p.pendingInterest > 0)
                            Text('• ${l10n.pendingInterest2Percent}: ${CalculationUtils.formatCurrency(p.pendingInterest)}', style: const TextStyle(fontSize: 12, color: AppColors.interest)),
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
    _loansReportFuture ??= provider.getLoanReport();

    return FutureBuilder<List<LoanReportItem>>(
      future: _loansReportFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debugPrint('[REPORT ERROR] Loans Overview UI error: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildErrorCard('Failed to load loans overview: ${snapshot.error}', () {
                _ensureTabLoaded(2, forceRefresh: true);
              }),
            ),
          );
        }

        final loans = snapshot.data ?? [];

        if (loans.isEmpty) {
          return Center(child: Text(l10n.noLoansIssuedYet, style: const TextStyle(color: AppColors.textMuted)));
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
                      _smallStat(l10n.originalLoan, CalculationUtils.formatCurrency(item.loan.originalPrincipal)),
                      _smallStat(l10n.principalPaid, CalculationUtils.formatCurrency(item.totalPrincipalPaid)),
                      _smallStat(l10n.interestPaid2Percent, CalculationUtils.formatCurrency(item.totalInterestPaid)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${l10n.remaining}: ${CalculationUtils.formatCurrency(item.currentPendingPrincipal)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.error)),
                      Text('${l10n.repayments}: ${item.repaymentCount}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
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

  Widget _buildErrorCard(String message, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
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
                    items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(l10n.localeName == 'mr' ? CalculationUtils.getMonthNameMarathi(i + 1) : CalculationUtils.getMonthName(i + 1)))),
                    onChanged: (val) {
                      if (val != null) _onDateChanged(val, _selectedYear);
                    },
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
                    onChanged: (val) {
                      if (val != null) _onDateChanged(_selectedMonth, val);
                    },
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

      final Map<String, String> labels = {
        'groupName': group.name,
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
        'isMarathi': (l10n.localeName == 'mr').toString(),
      };

      final pdfBytes = await PdfService.generateGroupReportBytes(
        report: report,
        labels: labels,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (isShare) {
        await ShareService.shareGroupReport(
          report: report,
          pdfBytes: pdfBytes,
          languageCode: l10n.localeName,
        );
      } else {
        await Printing.layoutPdf(
          name: 'BG_Group_Report_${_selectedMonth}_$_selectedYear.pdf',
          onLayout: (format) async => pdfBytes,
        );
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
