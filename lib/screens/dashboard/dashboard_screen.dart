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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Stream<BachatGatGroup?> _groupStream;
  late Stream<List<AppTransaction>> _activitiesStream;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BachatGatProvider>(context, listen: false);
    _groupStream = provider.watchGroup();
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
                  _buildHeader(context, l10n, group, provider),
                  const SizedBox(height: 25),

                  // 2. MAIN GROUP FUND CARD
                  _buildMainFundCard(context, l10n, group),
                  const SizedBox(height: 25),

                  // 3. QUICK ACTIONS
                  _SectionHeader(
                    title: l10n.quickActions,
                    onActionTap: () => _navigateToReports(context),
                  ),
                  const SizedBox(height: 15),
                  _buildQuickActions(context, l10n, provider),
                  const SizedBox(height: 25),

                  // 4. MONTHLY SAVINGS PROGRESS
                  _buildSavingsProgress(context, l10n, group),
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
                      return _buildRecentActivity(context, l10n, txSnapshot.data ?? []);
                    },
                  ),
                  const SizedBox(height: 20),

                  // 6. NEXT COLLECTION CARD
                  _buildNextCollectionCard(context, l10n, group),
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
  Widget _buildHeader(BuildContext context, AppLocalizations l10n, BachatGatGroup? group, BachatGatProvider provider) {
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
                  group?.name == 'Shivshahi Bachat Gat' || group?.name == null
                      ? l10n.defaultGroupName
                      : group!.name,
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
  Widget _buildMainFundCard(BuildContext context, AppLocalizations l10n, BachatGatGroup? group) {
    final savings = group?.totalSavings ?? 0.0;
    final loans = group?.totalOutstandingLoans ?? 0.0;
    final interest = group?.totalInterestCollected ?? 0.0;
    final availableFund = CalculationUtils.calculateAvailableFund(
      totalSavings: savings,
      outstandingLoans: loans,
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
  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n, BachatGatProvider provider) {
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
  Widget _buildSavingsProgress(BuildContext context, AppLocalizations l10n, BachatGatGroup? group) {
    final target = group?.monthlyTarget ?? 6000.0;
    final collected = group?.totalSavings ?? 5000.0;
    final progress = target > 0 ? (collected / target).clamp(0.0, 1.0) : 0.83;

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
                      const Text('August 2026', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _navigateToReports(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('August 2026', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.primary),
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
  Widget _buildRecentActivity(BuildContext context, AppLocalizations l10n, List<AppTransaction> activities) {
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
  Widget _buildNextCollectionCard(BuildContext context, AppLocalizations l10n, BachatGatGroup? group) {
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
    final groupName = group?.name == 'Shivshahi Bachat Gat' || group?.name == null
        ? l10n.defaultGroupName
        : group!.name;

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
            Text('${l10n.monthlyContribution}: ₹${group?.monthlyContributionAmount.toStringAsFixed(0) ?? '1000'} ${l10n.perMember}'),
            const SizedBox(height: 4),
            Text('${l10n.monthlyTarget}: ₹${group?.monthlyTarget.toStringAsFixed(0) ?? '6000'}'),
            const SizedBox(height: 4),
            Text('${l10n.createdDate}: ${CalculationUtils.formatShortDate(group?.createdAt ?? DateTime.now())}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.close)),
        ],
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context, BachatGatGroup? group) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.surfaceVariant, child: Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20)),
              title: const Text('Monthly Collection Due', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Monthly savings collection scheduled on the 10th.'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: AppColors.surfaceVariant, child: Icon(Icons.percent_rounded, color: AppColors.interest, size: 20)),
              title: const Text('2% Monthly Interest Rule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Interest is calculated automatically on outstanding principal.'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, BachatGatGroup? group, BachatGatProvider provider) {
    final nameController = TextEditingController(text: group?.name ?? 'Shivshahi Bachat Gat');
    final targetController = TextEditingController(text: group?.monthlyTarget.toStringAsFixed(0) ?? '6000');
    final haftaController = TextEditingController(text: group?.monthlyContributionAmount.toStringAsFixed(0) ?? '1000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Group Settings & Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Group Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: haftaController,
                decoration: const InputDecoration(labelText: 'Default Monthly Contribution (₹)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                decoration: const InputDecoration(labelText: 'Monthly Target (₹)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await provider.updateGroupSettings(
                name: nameController.text,
                monthlyContributionAmount: double.tryParse(haftaController.text),
                monthlyTarget: double.tryParse(targetController.text),
              );
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings updated successfully')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddInvestmentDialog(BuildContext context, BachatGatProvider provider) {
    provider.watchMembers().first.then((members) {
      if (!context.mounted) return;
      if (members.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a member first')));
        return;
      }

      Member? selectedMember;
      Loan? memberActiveLoan;
      final haftaController = TextEditingController();
      final principalController = TextEditingController(text: '0');
      final now = DateTime.now();
      int selectedMonth = now.month;
      int selectedYear = now.year;
      double calculatedInterest = 0.0;

      showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final hafta = double.tryParse(haftaController.text) ?? 0.0;
            final principal = double.tryParse(principalController.text) ?? 0.0;
            final totalCalculated = hafta + calculatedInterest + principal;

            return AlertDialog(
              title: const Text('Record Monthly Collection'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<Member>(
                      items: members.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                      onChanged: (val) async {
                        selectedMember = val;
                        if (val != null) {
                          haftaController.text = val.monthlyContribution.toStringAsFixed(0);
                          final loans = await provider.watchLoans(memberId: val.id).first;
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
                      decoration: const InputDecoration(labelText: 'Select Member'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedMonth,
                            items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(CalculationUtils.getMonthName(i + 1)))),
                            onChanged: (val) => setDialogState(() => selectedMonth = val!),
                            decoration: const InputDecoration(labelText: 'Month'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: selectedYear,
                            items: [now.year - 1, now.year, now.year + 1].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                            onChanged: (val) => setDialogState(() => selectedYear = val!),
                            decoration: const InputDecoration(labelText: 'Year'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: haftaController,
                      decoration: const InputDecoration(labelText: 'Regular Hafta (₹)'),
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
                              'Active Loan: ₹${memberActiveLoan!.pendingPrincipal.toStringAsFixed(0)} @ ${memberActiveLoan!.interestRate}%/mo',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Interest Due: ₹${calculatedInterest.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppColors.interest, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: principalController,
                        decoration: const InputDecoration(labelText: 'Loan Principal Repayment (₹) (Optional)'),
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
                          const Text('Total Payment:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedMember != null && totalCalculated > 0) {
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
                            ? 'Monthly Payment - ${CalculationUtils.getMonthName(selectedMonth)} $selectedYear (Hafta: ₹$hafta, Interest: ₹$calculatedInterest, Principal: ₹$principal)'
                            : 'Monthly Contribution - ${CalculationUtils.getMonthName(selectedMonth)} $selectedYear',
                      );

                      await provider.recordContribution(
                        contribution,
                        tx,
                        loan: memberActiveLoan,
                        repayment: repayment,
                      );

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Record'),
                ),
              ],
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
            child: Text(l10n.viewAll, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
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
