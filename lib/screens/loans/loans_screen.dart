import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bachat_gat_provider.dart';
import '../../models/loan.dart';
import '../../models/member.dart';
import '../../app/app_colors.dart';
import '../../core/utils/calculation_utils.dart';
import '../../l10n/app_localizations.dart';
import 'loan_detail_screen.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  late Stream<List<Loan>> _loansStream;
  late Stream<List<Member>> _membersStream;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BachatGatProvider>(context, listen: false);
    _loansStream = provider.watchLoans();
    _membersStream = provider.watchMembers();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Loan>>(
      stream: _loansStream,
      builder: (context, loanSnapshot) {
        if (loanSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final allLoans = loanSnapshot.data ?? [];
        final activeLoans = allLoans.where((l) => l.status == LoanStatus.active).toList();
        final closedLoans = allLoans.where((l) => l.status == LoanStatus.closed).toList();

        return StreamBuilder<List<Member>>(
          stream: _membersStream,
          builder: (context, memberSnapshot) {
            final membersMap = {for (var m in memberSnapshot.data ?? []) m.id: m.name};

            return DefaultTabController(
              length: 2,
              child: Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  title: Text(l10n.manageLoans),
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  bottom: TabBar(
                    tabs: [
                      Tab(text: l10n.activeLoansTab),
                      Tab(text: l10n.closedLoansTab),
                    ],
                    indicatorColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                body: TabBarView(
                  children: [
                    _LoanList(loans: activeLoans, membersMap: Map<String, String>.from(membersMap)),
                    _LoanList(loans: closedLoans, membersMap: Map<String, String>.from(membersMap)),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }
}

class _LoanList extends StatelessWidget {
  final List<Loan> loans;
  final Map<String, String> membersMap;

  const _LoanList({required this.loans, required this.membersMap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(l10n.noLoansFound, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: loans.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final loan = loans[index];
        return _LoanCard(
          loan: loan,
          memberName: membersMap[loan.memberId] ?? 'Unknown',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoanDetailScreen(
                  loan: loan,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LoanCard extends StatelessWidget {
  final Loan loan;
  final String memberName;
  final VoidCallback onTap;

  const _LoanCard({required this.loan, required this.memberName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = loan.originalPrincipal > 0 ? (1 - (loan.pendingPrincipal / loan.originalPrincipal)) : 1.0;
    final rateStr = l10n.localeName == 'mr'
        ? (loan.interestRate == 2 ? '२% / महिना' : '${loan.interestRate}% / महिना')
        : '${loan.interestRate}% / mo';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(memberName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                        const SizedBox(height: 4),
                        Text(
                          CalculationUtils.formatShortDate(loan.loanDate),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CalculationUtils.formatCurrency(loan.originalPrincipal),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSmallInfo(l10n.interestRate, rateStr),
                  _buildSmallInfo(l10n.outstanding, CalculationUtils.formatCurrency(loan.pendingPrincipal)),
                  _buildSmallInfo(l10n.repaid, '${(progress * 100).toStringAsFixed(0)}%'),
                ],
              ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.divider,
                  color: AppColors.success,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
      ],
    );
  }
}
