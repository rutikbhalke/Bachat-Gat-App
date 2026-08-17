import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../app/app_colors.dart';
import '../../providers/locale_provider.dart';
import '../../providers/bachat_gat_provider.dart';
import '../../models/group.dart';
import '../../models/transaction.dart';
import '../../core/utils/calculation_utils.dart';

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
                  _buildHeader(context, l10n, group),
                  const SizedBox(height: 25),

                  // 2. MAIN GROUP FUND CARD
                  _buildMainFundCard(context, l10n, group),
                  const SizedBox(height: 25),

                  // 3. QUICK ACTIONS
                  _SectionHeader(title: l10n.quickActions, onActionTap: () {}),
                  const SizedBox(height: 15),
                  _buildQuickActions(context, l10n),
                  const SizedBox(height: 25),

                  // 4. MONTHLY SAVINGS PROGRESS
                  _buildSavingsProgress(context, l10n, group),
                  const SizedBox(height: 25),

                  // 5. RECENT ACTIVITY
                  _SectionHeader(title: l10n.recentActivity, onActionTap: () {}),
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

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, BachatGatGroup? group) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.group_rounded, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.goodMorning} 👋', style: Theme.of(context).textTheme.bodyMedium),
              Text(group?.name ?? 'Shivshahi Bachat Gat', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        _buildLanguageSelector(context),
        const SizedBox(width: 8),
        Stack(
          children: [
            _buildRoundButton(Icons.notifications_none_rounded),
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
        _buildRoundButton(Icons.person_outline_rounded),
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

  Widget _buildRoundButton(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, color: AppColors.textPrimary, size: 20),
    );
  }

  Widget _buildMainFundCard(BuildContext context, AppLocalizations l10n, BachatGatGroup? group) {
    final fund = group?.totalFund ?? 0.0;
    final savings = group?.totalSavings ?? 0.0;
    final loans = group?.totalOutstandingLoans ?? 0.0;
    final interest = group?.totalInterestCollected ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
          Text(
            l10n.totalGroupFund,
            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CalculationUtils.formatCurrency(fund),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('8.4%', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFundStat(l10n.totalSavings, CalculationUtils.formatCurrency(savings), Icons.account_balance_wallet_outlined),
              _buildFundStat(l10n.activeLoans, CalculationUtils.formatCurrency(loans), Icons.upload_rounded),
              _buildFundStat(l10n.totalInterest, CalculationUtils.formatCurrency(interest), Icons.percent_rounded),
              _buildFundStat(l10n.available, CalculationUtils.formatCurrency(fund), Icons.account_balance_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFundStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 12,
      childAspectRatio: 0.75,
      children: [
        _buildActionItem(context, l10n.members, l10n.manage, Icons.people_outline_rounded, AppColors.info),
        _buildActionItem(context, l10n.addSavings, l10n.collect, Icons.savings_outlined, AppColors.success),
        _buildActionItem(context, l10n.loans, l10n.manage, Icons.account_balance_rounded, AppColors.warning),
        _buildActionItem(context, l10n.reports, l10n.view, Icons.bar_chart_rounded, AppColors.primary),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Column(
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
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildSavingsProgress(BuildContext context, AppLocalizations l10n, BachatGatGroup? group) {
    final target = group?.monthlyTarget ?? 6000.0;
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
                Container(
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
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: 0.83,
                        strokeWidth: 8,
                        backgroundColor: AppColors.divider,
                        color: AppColors.primary,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      children: [
                        const Text('83%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        Text(l10n.completed, style: const TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 25),
                Expanded(
                  child: Column(
                    children: [
                      _ProgressRow(label: l10n.collected, value: '₹5,000', color: AppColors.success),
                      const SizedBox(height: 12),
                      _ProgressRow(label: l10n.target, value: '₹$target', color: AppColors.textPrimary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            const LinearProgressIndicator(
              value: 0.83,
              minHeight: 10,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.people_outline_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('5 of 6 members have contributed', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, AppLocalizations l10n, List<AppTransaction> activities) {
    if (activities.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text('No recent activity'),
      ));
    }

    return Column(
      children: activities.map((tx) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ActivityItem(
          icon: tx.type == TransactionType.loanIssue ? Icons.trending_up_rounded : Icons.download_rounded,
          color: tx.type == TransactionType.loanIssue ? AppColors.warning : AppColors.success,
          title: tx.description ?? tx.type.name,
          subtitle: '${tx.memberName} • ${tx.date.hour}:${tx.date.minute}',
          amount: tx.type == TransactionType.loanIssue ? '- ₹${tx.amount}' : '+ ₹${tx.amount}',
        ),
      )).toList(),
    );
  }

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
                const Text('15 Aug 2026, Friday', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onActionTap;
  const _SectionHeader({required this.title, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        GestureDetector(
          onTap: onActionTap,
          child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
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
