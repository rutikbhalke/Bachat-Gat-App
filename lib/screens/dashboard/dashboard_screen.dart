import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../providers/locale_provider.dart';
import '../../providers/bachat_gat_provider.dart';
import '../../models/group.dart';
import '../../models/member.dart';
import '../../models/loan.dart';
import '../../models/loan_repayment.dart';
import '../../models/monthly_contribution.dart';
import '../../models/transaction.dart';
import '../../core/utils/calculation_utils.dart';
import '../members/members_screen.dart';
import '../loans/loans_screen.dart';
import '../reports/reports_screen.dart';
import '../transactions/transactions_screen.dart';
import '../../widgets/common/searchable_member_picker.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedSavingsMonth = DateTime.now().month;
  int _selectedSavingsYear = DateTime.now().year;
  late Stream<BachatGatGroup?> _groupStream;
  late Stream<List<Member>> _membersStream;
  late Stream<List<MonthlyContribution>> _contributionsStream;
  late Stream<List<Loan>> _loansStream;
  late Stream<List<AppTransaction>> _activitiesStream;

  List<MonthYearOption> _buildMonthYearOptions(List<MonthlyContribution> contributions) {
    final now = DateTime.now();
    final options = <MonthYearOption>{};

    // 1. Include standard span around current year
    for (int y = now.year + 1; y >= now.year - 2; y--) {
      for (int m = 12; m >= 1; m--) {
        options.add(MonthYearOption(month: m, year: y));
      }
    }

    // 2. Add any existing contribution months if any exist beyond standard range
    for (final c in contributions) {
      options.add(MonthYearOption(month: c.month, year: c.year));
    }

    // 3. Ensure currently selected month is always included
    options.add(MonthYearOption(month: _selectedSavingsMonth, year: _selectedSavingsYear));

    // Sort descending: newest first (e.g. Aug 2026, Jul 2026, Jun 2026...)
    final list = options.toList();
    list.sort((a, b) => (b.year * 12 + b.month).compareTo(a.year * 12 + a.month));
    return list;
  }

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BachatGatProvider>(context, listen: false);
    _groupStream = provider.watchGroup();
    _membersStream = provider.watchMembers(activeOnly: true);
    _contributionsStream = provider.watchContributions();
    _loansStream = provider.watchLoans();
    _activitiesStream = provider.watchRecentActivities();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<BachatGatProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<BachatGatGroup?>(
          stream: _groupStream,
          builder: (context, groupSnapshot) {
            final group = groupSnapshot.data;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. TOP HEADER
                  _buildHeader(context, group, provider),
                  const SizedBox(height: 25),

                  // 2. MAIN GROUP FUND CARD
                  StreamBuilder<List<Loan>>(
                    stream: _loansStream,
                    builder: (context, loansSnapshot) {
                      return _buildMainFundCard(context, group, loansSnapshot.data ?? []);
                    },
                  ),
                  const SizedBox(height: 25),

                  // 3. QUICK ACTIONS
                  _SectionHeader(
                    title: l10n.quickActions,
                    onActionTap: () => _navigateToReports(context),
                  ),
                  const SizedBox(height: 15),
                  _buildQuickActions(context, provider),
                  const SizedBox(height: 25),

                  // 4. MONTHLY SAVINGS PROGRESS
                  StreamBuilder<List<Member>>(
                    stream: _membersStream,
                    builder: (context, membersSnapshot) {
                      final members = membersSnapshot.data ?? [];
                      return StreamBuilder<List<MonthlyContribution>>(
                        stream: _contributionsStream,
                        builder: (context, contribsSnapshot) {
                          final contribs = contribsSnapshot.data ?? [];
                          return _buildSavingsProgress(context, group, members, contribs);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 25),

                  // 5. RECENT ACTIVITY
                  _SectionHeader(
                    title: l10n.recentActivity,
                    onActionTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                    ),
                  ),
                  const SizedBox(height: 15),
                  StreamBuilder<List<AppTransaction>>(
                    stream: _activitiesStream,
                    builder: (context, txSnapshot) {
                      return _buildRecentActivity(context, txSnapshot.data ?? []);
                    },
                  ),
                  const SizedBox(height: 20),

                  // 6. NEXT COLLECTION CARD
                  _buildNextCollectionCard(context, group),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- NAVIGATION HELPERS ---
  void _navigateToMembers(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MembersScreen()));
  }

  void _navigateToLoans(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoansScreen()));
  }

  void _navigateToReports(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
  }

  // --- HEADER ---
  Widget _buildHeader(BuildContext context, BachatGatGroup? group, BachatGatProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        InkWell(
          onTap: () => _showGroupInfoDialog(context, group),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.group_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => _showGroupInfoDialog(context, group),
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${l10n.goodMorning} 👋', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  CalculationUtils.resolveGroupName(group?.name, l10n.defaultGroupName),
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        _buildLanguageSelector(context),
        const SizedBox(width: 8),
        Stack(
          children: [
            _buildRoundButton(
              Icons.notifications_none_rounded,
              onTap: () => _showNotificationsDialog(context, group),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        _buildRoundButton(
          Icons.person_outline_rounded,
          onTap: () => _showProfileDialog(context, group, provider),
        ),
      ],
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;

    return PopupMenuButton<String>(
      onSelected: (String code) {
        localeProvider.setLocale(Locale(code));
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'en', child: Text('English')),
        const PopupMenuItem(value: 'mr', child: Text('मराठी')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLocale == 'en' ? 'EN' : 'मराठी',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.textPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundButton(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  // --- MAIN FUND CARD ---
  Widget _buildMainFundCard(BuildContext context, BachatGatGroup? group, List<Loan> loansList) {
    final l10n = AppLocalizations.of(context)!;
    final savings = (group != null && group.totalSavings >= 0) ? group.totalSavings : 0.0;
    final interest = (group != null && group.totalInterestCollected >= 0) ? group.totalInterestCollected : 0.0;
    final calculatedActiveLoans = CalculationUtils.calculateActiveLoansOutstanding(loansList);
    final loans = (loansList.isNotEmpty || calculatedActiveLoans > 0)
        ? calculatedActiveLoans
        : ((group != null && group.totalOutstandingLoans >= 0) ? group.totalOutstandingLoans : 0.0);
    final availableFund = CalculationUtils.calculateAvailableFund(
      totalSavings: savings,
      outstandingLoans: loans,
      totalInterest: interest,
    );
    final hasInconsistency = CalculationUtils.hasFundInconsistency(
      totalSavings: savings,
      outstandingLoans: loans,
    );
    final totalGroupFund = CalculationUtils.calculateTotalGroupFund(
      availableCash: availableFund,
      outstandingLoans: loans,
    );

    return InkWell(
      onTap: () => _navigateToReports(context),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.totalGroupFund,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 12),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CalculationUtils.formatCurrency(totalGroupFund),
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('8.4%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFundStat(
                  l10n.totalSavings,
                  CalculationUtils.formatCurrency(savings),
                  Icons.account_balance_wallet_outlined,
                  onTap: () => _navigateToReports(context),
                ),
                _buildFundStat(
                  l10n.activeLoans,
                  CalculationUtils.formatCurrency(loans),
                  Icons.upload_rounded,
                  onTap: () => _navigateToLoans(context),
                ),
                _buildFundStat(
                  l10n.totalInterest,
                  CalculationUtils.formatCurrency(interest),
                  Icons.percent_rounded,
                  onTap: () => _navigateToReports(context),
                ),
                _buildFundStat(
                  l10n.available,
                  CalculationUtils.formatCurrency(availableFund),
                  Icons.account_balance_rounded,
                  onTap: () => _navigateToReports(context),
                ),
              ],
            ),
            if (hasInconsistency) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Data Notice: Active loans (${CalculationUtils.formatCurrency(loans)}) exceed savings (${CalculationUtils.formatCurrency(savings)}). Loan lending blocked until reconciled.',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFundStat(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- QUICK ACTIONS ---
  Widget _buildQuickActions(BuildContext context, BachatGatProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 12,
      childAspectRatio: 0.75,
      children: [
        _buildActionItem(
          context,
          l10n.members,
          l10n.manage,
          Icons.people_outline_rounded,
          AppColors.info,
          () => _navigateToMembers(context),
        ),
        _buildActionItem(
          context,
          l10n.addSavings,
          l10n.collect,
          Icons.savings_outlined,
          AppColors.success,
          () => _showAddInvestmentDialog(context, provider),
        ),
        _buildActionItem(
          context,
          l10n.loans,
          l10n.manage,
          Icons.account_balance_rounded,
          AppColors.warning,
          () => _navigateToLoans(context),
        ),
        _buildActionItem(
          context,
          l10n.reports,
          l10n.view,
          Icons.bar_chart_rounded,
          AppColors.primary,
          () => _navigateToReports(context),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- MONTHLY SAVINGS PROGRESS ---
  Widget _buildSavingsProgress(
    BuildContext context,
    BachatGatGroup? group,
    List<Member> members,
    List<MonthlyContribution> contributions,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final target = CalculationUtils.calculateMonthlySavingsTarget(
      members,
      perShareAmount: group?.monthlyContributionAmount,
      fallbackTarget: group?.monthlyTarget,
    );

    final collected = CalculationUtils.calculateCurrentMonthCollectedSavings(
      contributions,
      month: _selectedSavingsMonth,
      year: _selectedSavingsYear,
    );

    final progress = CalculationUtils.calculateSavingsProgressRatio(
      collected: collected,
      target: target,
    );

    final selectedMonthDisplay = '${CalculationUtils.getMonthName(_selectedSavingsMonth, locale: l10n.localeName)} $_selectedSavingsYear';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.monthlySavingsProgress,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(selectedMonthDisplay, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<MonthYearOption>(
                  tooltip: l10n.month,
                  initialValue: MonthYearOption(month: _selectedSavingsMonth, year: _selectedSavingsYear),
                  onSelected: (MonthYearOption selected) {
                    setState(() {
                      _selectedSavingsMonth = selected.month;
                      _selectedSavingsYear = selected.year;
                    });
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  elevation: 4,
                  constraints: const BoxConstraints(maxHeight: 320),
                  itemBuilder: (context) {
                    final options = _buildMonthYearOptions(contributions);
                    return options.map((option) {
                      final isSelected = option.month == _selectedSavingsMonth && option.year == _selectedSavingsYear;
                      final label = '${CalculationUtils.getMonthName(option.month, locale: l10n.localeName)} ${option.year}';
                      return PopupMenuItem<MonthYearOption>(
                        value: option,
                        height: 38,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedMonthDisplay,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: AppColors.divider,
                        color: AppColors.primary,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      children: [
                        Text('${(progress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        Text(l10n.completed, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 25),
                Expanded(
                  child: Column(
                    children: [
                      _ProgressRow(
                        label: l10n.collected,
                        value: CalculationUtils.formatCurrency(collected),
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 12),
                      _ProgressRow(
                        label: l10n.target,
                        value: CalculationUtils.formatCurrency(target),
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.people_outline_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.activeGroupTargetProgress,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- RECENT ACTIVITY ---
  Widget _buildRecentActivity(BuildContext context, List<AppTransaction> activities) {
    final l10n = AppLocalizations.of(context)!;
    if (activities.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(l10n.noRecentActivity),
      ));
    }

    return Column(
      children: activities.take(5).map((tx) {
        final localizedTitle = CalculationUtils.localizeTransactionDescription(
          tx.description ?? tx.type.name,
          isMarathi: l10n.localeName == 'mr',
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionsScreen()),
            ),
            borderRadius: BorderRadius.circular(16),
            child: _ActivityItem(
              icon: tx.type == TransactionType.loanIssue ? Icons.trending_up_rounded : Icons.download_rounded,
              color: tx.type == TransactionType.loanIssue ? AppColors.warning : AppColors.success,
              title: localizedTitle,
              subtitle: '${tx.memberName} • ${CalculationUtils.formatShortDate(tx.date)}',
              amount: tx.type == TransactionType.loanIssue
                  ? '- ${CalculationUtils.formatCurrency(tx.amount)}'
                  : '+ ${CalculationUtils.formatCurrency(tx.amount)}',
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- NEXT COLLECTION CARD ---
  Widget _buildNextCollectionCard(BuildContext context, BachatGatGroup? group) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.nextCollection, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                Text(l10n.tenthOfEveryMonth, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _navigateToReports(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l10n.viewDetails, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // --- DIALOGS ---
  void _showGroupInfoDialog(BuildContext context, BachatGatGroup? group) {
    final l10n = AppLocalizations.of(context)!;
    final groupName = CalculationUtils.resolveGroupName(group?.name, l10n.defaultGroupName);
    final provider = Provider.of<BachatGatProvider>(context, listen: false);
    provider.getMembers(activeOnly: true).then((activeMembers) {
      if (!context.mounted) return;
      final contributionPerShare = group?.monthlyContributionAmount ?? 1000.0;
      final calculatedTarget = CalculationUtils.calculateMonthlySavingsTarget(
        activeMembers,
        perShareAmount: contributionPerShare,
        fallbackTarget: group?.monthlyTarget,
      );

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.group_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(groupName)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.groupId}: ${group?.id ?? 'shivshahi_group_001'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Text('${l10n.monthlyContribution}: ₹${contributionPerShare.toStringAsFixed(0)} ${l10n.perShareAmount}'),
              const SizedBox(height: 4),
              Text('${l10n.monthlyTarget}: ₹${calculatedTarget.toStringAsFixed(0)}'),
              const SizedBox(height: 4),
              Text('${l10n.createdDate}: ${CalculationUtils.formatShortDate(group?.createdAt ?? DateTime.now())}'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.close)),
          ],
        ),
      );
    });
  }

  void _showNotificationsDialog(BuildContext context, BachatGatGroup? group) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(l10n.notifications, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.surfaceVariant, child: Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20)),
              title: Text(l10n.monthlyCollectionDue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(l10n.collectionScheduledTenth),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.surfaceVariant, child: Icon(Icons.percent_rounded, color: AppColors.interest, size: 20)),
              title: Text(l10n.interestRule2Percent, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(l10n.interestCalculatedAutomatically),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.gotIt)),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, BachatGatGroup? group, BachatGatProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    provider.getMembers(activeOnly: true).then((activeMembers) {
      if (!context.mounted) return;

      final initialHafta = group?.monthlyContributionAmount ?? 1000.0;
      final initialDueDay = group?.monthlyHaftaDay ?? 10;
      final initialTarget = CalculationUtils.calculateMonthlySavingsTarget(
        activeMembers,
        perShareAmount: initialHafta,
        fallbackTarget: group?.monthlyTarget,
      );

      final nameController = TextEditingController(text: group?.name ?? 'Chhatrapati Bachat Gat, Ghargaon Stand');
      final haftaController = TextEditingController(text: initialHafta.toStringAsFixed(0));
      final dueDayController = TextEditingController(text: initialDueDay.toString());
      final targetController = TextEditingController(text: initialTarget.toStringAsFixed(0));

      void recalculateTarget() {
        final newHafta = double.tryParse(haftaController.text) ?? initialHafta;
        final newTarget = CalculationUtils.calculateMonthlySavingsTarget(
          activeMembers,
          perShareAmount: newHafta,
          fallbackTarget: group?.monthlyTarget,
        );
        targetController.text = newTarget.toStringAsFixed(0);
      }

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.groupSettingsProfile),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: l10n.groupName),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: haftaController,
                      decoration: InputDecoration(labelText: l10n.defaultContribution),
                      keyboardType: TextInputType.number,
                      onChanged: (val) {
                        setDialogState(() {
                          recalculateTarget();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dueDayController,
                      decoration: InputDecoration(
                        labelText: l10n.monthlyHaftaDueDate,
                        helperText: '1 - 28',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: targetController,
                      decoration: InputDecoration(labelText: l10n.monthlyTarget),
                      keyboardType: TextInputType.number,
                      readOnly: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
                ElevatedButton(
                  onPressed: () async {
                    final updatedHafta = double.tryParse(haftaController.text) ?? initialHafta;
                    final parsedDueDay = int.tryParse(dueDayController.text) ?? initialDueDay;
                    final updatedDueDay = parsedDueDay.clamp(1, 28);
                    final calculatedTarget = CalculationUtils.calculateMonthlySavingsTarget(
                      activeMembers,
                      perShareAmount: updatedHafta,
                      fallbackTarget: group?.monthlyTarget,
                    );
                    await provider.updateGroupSettings(
                      name: nameController.text.trim().isEmpty ? 'Chhatrapati Bachat Gat, Ghargaon Stand' : nameController.text.trim(),
                      monthlyContributionAmount: updatedHafta,
                      monthlyTarget: calculatedTarget,
                      monthlyHaftaDay: updatedDueDay,
                    );
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.settingsUpdatedSuccessfully)));
                  },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  void _showAddInvestmentDialog(BuildContext context, BachatGatProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    provider.watchMembers().first.then((members) {
      if (!context.mounted) return;
      if (members.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noMembersFound)));
        return;
      }

      Member? selectedMember;
      Loan? memberActiveLoan;
      final searchController = TextEditingController();
      String memberSearchQuery = '';
      final haftaController = TextEditingController();
      final principalController = TextEditingController(text: '0');
      final now = DateTime.now();
      final activeCycle = CalculationUtils.getActiveCycleForDate(now, dueDay: 10);
      int selectedMonth = activeCycle.month;
      int selectedYear = activeCycle.year;
      double calculatedInterest = 0.0;
      bool isSubmitting = false;

      showDialog(
        context: context,
        builder: (dialogContext) => StreamBuilder<List<MonthlyContribution>>(
          stream: provider.watchContributions(),
          builder: (dialogContext, contribSnapshot) {
            return StatefulBuilder(
              builder: (dialogContext, setDialogState) {
                final contributions = contribSnapshot.data ?? [];

                // Map contributions for selectedMonth & selectedYear
                final currentMonthContribsByMember = <String, MonthlyContribution>{};
                for (final c in contributions) {
                  if (c.month == selectedMonth && c.year == selectedYear) {
                    currentMonthContribsByMember[c.memberId] = c;
                  }
                }

                // Compute pending amounts for all active members
                final pendingAmounts = <String, double>{};
                final pendingMembers = <Member>[];

                for (final member in members) {
                  if (member.status != MemberStatus.active) continue;
                  final contrib = currentMonthContribsByMember[member.id];
                  final remaining = CalculationUtils.calculateMemberPendingHafta(
                    member: member,
                    contribution: contrib,
                  );

                  if (remaining > 0) {
                    pendingAmounts[member.id] = remaining;
                    pendingMembers.add(member);
                  }
                }

                // Ensure selectedMember is valid and in pending list
                if (selectedMember != null) {
                  final matching = pendingMembers.where((m) => m.id == selectedMember!.id).toList();
                  if (matching.isEmpty) {
                    selectedMember = null;
                    memberActiveLoan = null;
                    calculatedInterest = 0.0;
                    haftaController.clear();
                  } else {
                    selectedMember = matching.first;
                  }
                }

                // Filter pending members based on search query
                final searchedPendingMembers = pendingMembers.where((m) {
                  if (memberSearchQuery.isEmpty) return true;
                  final cleanPhone = m.phone.replaceAll(RegExp(r'\D'), '');
                  return m.name.toLowerCase().contains(memberSearchQuery) ||
                      cleanPhone.contains(memberSearchQuery);
                }).toList();

                final sortedSearched = CalculationUtils.sortMembersByBaseNameAndSequence(searchedPendingMembers);
                final dropdownMembers = List<Member>.from(sortedSearched);
                if (selectedMember != null &&
                    !dropdownMembers.any((m) => m.id == selectedMember!.id) &&
                    pendingMembers.any((m) => m.id == selectedMember!.id)) {
                  dropdownMembers.insert(0, selectedMember!);
                }

                final hafta = double.tryParse(haftaController.text) ?? 0.0;
                final principal = double.tryParse(principalController.text) ?? 0.0;
                final totalCalculated = hafta + calculatedInterest + principal;

                return AlertDialog(
                  title: Text(l10n.recordMonthlyCollection),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Searchable Member Selector Field with Modal Search List
                        InkWell(
                          onTap: pendingMembers.isEmpty
                              ? null
                              : () async {
                                  final picked = await SearchableMemberPicker.show(
                                    context: context,
                                    pendingMembers: pendingMembers,
                                    pendingAmounts: pendingAmounts,
                                    initiallySelected: selectedMember,
                                  );
                                  if (picked != null) {
                                    selectedMember = picked;
                                    final remaining = pendingAmounts[picked.id] ?? picked.monthlyContribution;
                                    haftaController.text = remaining.toStringAsFixed(0);
                                    final loans = await provider.watchLoans(memberId: picked.id).first;
                                    final active = loans.where((l) => l.status == LoanStatus.active).toList();
                                    if (active.isNotEmpty) {
                                      memberActiveLoan = active.first;
                                      calculatedInterest = CalculationUtils.calculateMonthlyInterest(
                                        outstandingPrincipal: memberActiveLoan!.pendingPrincipal,
                                        annualRate: memberActiveLoan!.interestRate,
                                      );
                                    } else {
                                      memberActiveLoan = null;
                                      calculatedInterest = 0.0;
                                    }
                                    setDialogState(() {});
                                  }
                                },
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.selectMember,
                              hintText: l10n.searchMembers,
                              prefixIcon: const Icon(Icons.person_search_rounded, size: 22, color: AppColors.primary),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selectedMember != null)
                                    IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        setDialogState(() {
                                          selectedMember = null;
                                          memberActiveLoan = null;
                                          calculatedInterest = 0.0;
                                          haftaController.clear();
                                        });
                                      },
                                    ),
                                  const Icon(Icons.arrow_drop_down_rounded, size: 24, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            child: Text(
                              selectedMember != null
                                  ? '${selectedMember!.name} (₹${(pendingAmounts[selectedMember!.id] ?? selectedMember!.monthlyContribution).toStringAsFixed(0)})'
                                  : (pendingMembers.isEmpty
                                      ? l10n.allCollectionsUpToDate
                                      : l10n.searchMembers),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selectedMember != null ? FontWeight.bold : FontWeight.normal,
                                color: selectedMember != null ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: selectedMonth,
                                items: List.generate(
                                  12,
                                  (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text(CalculationUtils.getMonthName(i + 1, locale: l10n.localeName)),
                                  ),
                                ),
                                onChanged: (val) {
                                  if (val != null && val != selectedMonth) {
                                    setDialogState(() {
                                      selectedMonth = val;
                                      selectedMember = null;
                                      memberActiveLoan = null;
                                      calculatedInterest = 0.0;
                                      haftaController.clear();
                                    });
                                  }
                                },
                                decoration: InputDecoration(labelText: l10n.month),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: selectedYear,
                                items: [now.year - 1, now.year, now.year + 1]
                                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null && val != selectedYear) {
                                    setDialogState(() {
                                      selectedYear = val;
                                      selectedMember = null;
                                      memberActiveLoan = null;
                                      calculatedInterest = 0.0;
                                      haftaController.clear();
                                    });
                                  }
                                },
                                decoration: InputDecoration(labelText: l10n.year),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: haftaController,
                          decoration: InputDecoration(labelText: l10n.regularHaftaLabel),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setDialogState(() {}),
                        ),
                    if (memberActiveLoan != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l10n.activeLoan}: ₹${memberActiveLoan!.pendingPrincipal.toStringAsFixed(0)} @ ${memberActiveLoan!.interestRate}%/${l10n.perMonth}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.interestDue}: ₹${calculatedInterest.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppColors.interest, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: principalController,
                        decoration: InputDecoration(labelText: l10n.loanPrincipalRepaymentOptional),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.totalPaymentLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            CalculationUtils.formatCurrency(totalCalculated),
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.success, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (selectedMember == null) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectMember)));
                            return;
                          }
                          if (hafta <= 0 && principal <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.totalPaymentLabel)));
                            return;
                          }
                          if (hafta < 0 || principal < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.totalPaymentLabel)));
                            return;
                          }
                          final maxAllowedHafta = pendingAmounts[selectedMember!.id] ?? selectedMember!.monthlyContribution;
                          if (hafta > maxAllowedHafta) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.regularHafta} cannot exceed remaining pending amount (₹${maxAllowedHafta.toStringAsFixed(0)})')));
                            return;
                          }
                          if (memberActiveLoan != null && principal > memberActiveLoan!.pendingPrincipal) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.principalCannotExceedPending)));
                            return;
                          }

                            setDialogState(() => isSubmitting = true);

                            try {
                              final recordDate = DateTime.now();
                              final periodSuffix = '${selectedYear}_${selectedMonth.toString().padLeft(2, '0')}';
                              
                              LoanRepayment? repayment;
                              if (memberActiveLoan != null) {
                                repayment = LoanRepayment(
                                  id: 'R_${memberActiveLoan!.id}_$periodSuffix',
                                  loanId: memberActiveLoan!.id,
                                  groupId: provider.groupId,
                                  memberId: selectedMember!.id,
                                  month: selectedMonth,
                                  year: selectedYear,
                                  openingPrincipal: memberActiveLoan!.pendingPrincipal,
                                  interestRate: memberActiveLoan!.interestRate,
                                  interestAmount: calculatedInterest,
                                  regularContribution: hafta,
                                  principalRepaid: principal,
                                  totalPaid: totalCalculated,
                                  closingPrincipal: memberActiveLoan!.pendingPrincipal - principal > 0
                                      ? memberActiveLoan!.pendingPrincipal - principal
                                      : 0.0,
                                  paymentDate: recordDate,
                                  createdAt: recordDate,
                                  updatedAt: recordDate,
                                );
                              }

                              final contribution = MonthlyContribution(
                                id: 'C_${selectedMember!.id}_$periodSuffix',
                                memberId: selectedMember!.id,
                                groupId: provider.groupId,
                                month: selectedMonth,
                                year: selectedYear,
                                regularHaftaAmount: hafta,
                                interestAmount: calculatedInterest,
                                loanPrincipalPaid: principal,
                                totalPaid: totalCalculated,
                                expectedAmount: selectedMember!.monthlyContribution,
                                paidAmount: totalCalculated,
                                status: hafta >= selectedMember!.monthlyContribution
                                    ? ContributionStatus.paid
                                    : ContributionStatus.partial,
                                paymentDate: recordDate,
                                createdAt: recordDate,
                                updatedAt: recordDate,
                              );

                              final tx = AppTransaction(
                                id: 'T_${selectedMember!.id}_$periodSuffix',
                                memberId: selectedMember!.id,
                                memberName: selectedMember!.name,
                                type: memberActiveLoan != null ? TransactionType.loanRepayment : TransactionType.monthlyInvestment,
                                amount: totalCalculated,
                                date: recordDate,
                                description: memberActiveLoan != null
                                    ? 'Monthly Payment - ${CalculationUtils.getMonthName(selectedMonth, locale: l10n.localeName)} $selectedYear (Hafta: ₹$hafta, Interest: ₹$calculatedInterest, Principal: ₹$principal)'
                                    : 'Monthly Contribution - ${CalculationUtils.getMonthName(selectedMonth, locale: l10n.localeName)} $selectedYear',
                              );

                              await provider.recordContribution(
                                contribution,
                                tx,
                                loan: memberActiveLoan,
                                repayment: repayment,
                              );

                              if (!dialogContext.mounted) return;
                              Navigator.pop(dialogContext);
                            } catch (e) {
                              setDialogState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                            }
                          },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.record),
                ),
              ],
            );
          },
        );
      },
    ),
  );
});
}
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onActionTap;
  const _SectionHeader({required this.title, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        InkWell(
          onTap: onActionTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              l10n.viewAll,
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ProgressRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? amount;
  const _ActivityItem({required this.icon, required this.color, required this.title, required this.subtitle, this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (amount != null)
            Text(amount!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}

class MonthYearOption {
  final int month;
  final int year;

  const MonthYearOption({required this.month, required this.year});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthYearOption &&
          runtimeType == other.runtimeType &&
          month == other.month &&
          year == other.year;

  @override
  int get hashCode => month.hashCode ^ year.hashCode;
}
