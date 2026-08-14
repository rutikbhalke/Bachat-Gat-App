import 'package:flutter/material.dart';
import '../../app/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER
              _buildHeader(context),
              const SizedBox(height: 25),

              // 2. MAIN GROUP FUND CARD
              _buildMainFundCard(context),
              const SizedBox(height: 25),

              // 3. QUICK ACTIONS
              _SectionHeader(title: 'Quick Actions', onActionTap: () {}),
              const SizedBox(height: 15),
              _buildQuickActions(context),
              const SizedBox(height: 25),

              // 4. MONTHLY SAVINGS PROGRESS
              _buildSavingsProgress(context),
              const SizedBox(height: 25),

              // 5. RECENT ACTIVITY
              _SectionHeader(title: 'Recent Activity', onActionTap: () {}),
              const SizedBox(height: 15),
              _buildRecentActivity(context),
              const SizedBox(height: 20),

              // 6. NEXT COLLECTION CARD
              _buildNextCollectionCard(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              Text('Good Morning 👋', style: Theme.of(context).textTheme.bodyMedium),
              Text('Shivshahi Bachat Gat', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
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

  Widget _buildMainFundCard(BuildContext context) {
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
          const Text(
            'TOTAL GROUP FUND',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '₹37,000',
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
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
              _buildFundStat('Total Savings', '₹37,000', Icons.account_balance_wallet_outlined),
              _buildFundStat('Active Loans', '₹8,000', Icons.upload_rounded),
              _buildFundStat('Total Interest', '₹200', Icons.percent_rounded),
              _buildFundStat('Available', '₹29,200', Icons.account_balance_rounded),
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

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 15,
      crossAxisSpacing: 12,
      childAspectRatio: 0.75,
      children: [
        _buildActionItem(context, 'Members', 'Manage', Icons.people_outline_rounded, AppColors.info),
        _buildActionItem(context, 'Add Savings', 'Collect', Icons.savings_outlined, AppColors.success),
        _buildActionItem(context, 'Loans', 'Manage', Icons.account_balance_rounded, AppColors.warning),
        _buildActionItem(context, 'Reports', 'View', Icons.bar_chart_rounded, AppColors.primary),
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

  Widget _buildSavingsProgress(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monthly Savings Progress', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('August 2026', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
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
                    SizedBox(
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
                    const Column(
                      children: [
                        Text('83%', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        Text('Completed', style: TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 25),
                const Expanded(
                  child: Column(
                    children: [
                      _ProgressRow(label: 'Collected', value: '₹5,000', color: AppColors.success),
                      SizedBox(height: 12),
                      _ProgressRow(label: 'Target', value: '₹6,000', color: AppColors.textPrimary),
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

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      children: [
        _ActivityItem(
          icon: Icons.download_rounded,
          color: AppColors.success,
          title: 'Monthly saving received',
          subtitle: 'Sunita Pawar • Today, 10:42 AM',
          amount: '+ ₹1,000',
        ),
        const SizedBox(height: 12),
        _ActivityItem(
          icon: Icons.trending_up_rounded,
          color: AppColors.warning,
          title: 'Loan repayment',
          subtitle: 'Ramesh Shinde • Yesterday, 6:15 PM',
          amount: '+ ₹500',
        ),
        const SizedBox(height: 12),
        _ActivityItem(
          icon: Icons.person_add_rounded,
          color: AppColors.info,
          title: 'New member added',
          subtitle: 'Meena Jadhav • 12 Aug 2026',
        ),
      ],
    );
  }

  Widget _buildNextCollectionCard(BuildContext context) {
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next Collection', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                Text('15 Aug 2026, Friday', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
            child: const Text('View Details', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
