import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../models/loan.dart';
import '../../app/app_colors.dart';
import '../../core/utils/calculation_utils.dart';
import 'loan_detail_screen.dart';

class LoansScreen extends StatefulWidget {
  final DataService dataService;

  const LoansScreen({super.key, required this.dataService});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  @override
  Widget build(BuildContext context) {
    final allLoans = widget.dataService.getLoans();
    final activeLoans = allLoans.where((l) => l.status == LoanStatus.active).toList();
    final closedLoans = allLoans.where((l) => l.status == LoanStatus.closed).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Manage Loans'),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active Loans'),
              Tab(text: 'Closed'),
            ],
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: TabBarView(
          children: [
            _LoanList(loans: activeLoans, dataService: widget.dataService, onRefresh: () => setState(() {})),
            _LoanList(loans: closedLoans, dataService: widget.dataService, onRefresh: () => setState(() {})),
          ],
        ),
      ),
    );
  }
}

class _LoanList extends StatelessWidget {
  final List<Loan> loans;
  final DataService dataService;
  final VoidCallback onRefresh;

  const _LoanList({required this.loans, required this.dataService, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No loans found', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    
    final members = {for (var m in dataService.getMembers()) m.id: m.name};

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: loans.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final loan = loans[index];
        return _LoanCard(
          loan: loan,
          memberName: members[loan.memberId] ?? 'Unknown',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoanDetailScreen(
                  dataService: dataService,
                  loan: loan,
                ),
              ),
            ).then((_) => onRefresh());
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
    final progress = loan.loanAmount > 0 ? (1 - (loan.outstandingPrincipal / loan.loanAmount)) : 1.0;

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
                    CalculationUtils.formatCurrency(loan.loanAmount),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSmallInfo('Interest Rate', '${loan.interestRate}% / mo'),
                  _buildSmallInfo('Outstanding', CalculationUtils.formatCurrency(loan.outstandingPrincipal)),
                  _buildSmallInfo('Repaid', '${(progress * 100).toStringAsFixed(0)}%'),
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
