import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bachat_gat_provider.dart';
import '../../models/loan.dart';
import '../../models/loan_repayment.dart';
import '../../app/app_colors.dart';
import '../../core/utils/calculation_utils.dart';

class LoanDetailScreen extends StatefulWidget {
  final Loan loan;

  const LoanDetailScreen({super.key, required this.loan});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  late Loan _loan;
  late Stream<List<LoanRepayment>> _repaymentsStream;

  @override
  void initState() {
    super.initState();
    _loan = widget.loan;
    final provider = Provider.of<BachatGatProvider>(context, listen: false);
    _repaymentsStream = provider.watchRepayments(loanId: _loan.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Details')),
      body: StreamBuilder<List<LoanRepayment>>(
        stream: _repaymentsStream,
        builder: (context, snapshot) {
          final repayments = snapshot.data ?? [];
          repayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

          final totalInterestPaid = repayments.fold<double>(0.0, (sum, r) => sum + r.interestAmount);
          final totalPrincipalPaid = repayments.fold<double>(0.0, (sum, r) => sum + r.principalRepaid);
          
          final currentInterest = CalculationUtils.calculateMonthlyInterest(
            outstandingPrincipal: _loan.pendingPrincipal,
            annualRate: _loan.interestRate,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(totalInterestPaid, totalPrincipalPaid),
                const SizedBox(height: 24),
                
                if (_loan.status == LoanStatus.active) ...[
                  Text('CURRENT MONTH INTEREST', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Interest for this month:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          CalculationUtils.formatCurrency(currentInterest),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                Text('REPAYMENT HISTORY', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 12),
                if (repayments.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No repayments recorded')))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: repayments.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final r = repayments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(CalculationUtils.formatShortDate(r.paymentDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  CalculationUtils.formatCurrency(r.totalPaid),
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.success),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _miniBadge('Interest: ${CalculationUtils.formatCurrency(r.interestAmount)}', AppColors.interest),
                                const SizedBox(width: 8),
                                _miniBadge('Principal: ${CalculationUtils.formatCurrency(r.principalRepaid)}', AppColors.success),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Remaining Balance: ${CalculationUtils.formatCurrency(r.closingPrincipal)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildOverviewCard(double interestPaid, double principalPaid) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _miniStat('Original Loan', CalculationUtils.formatCurrency(_loan.originalPrincipal)),
                _miniStat('Interest Rate', '${_loan.interestRate}% / mo'),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(child: _miniStat('Interest Paid', CalculationUtils.formatCurrency(interestPaid))),
                Expanded(child: _miniStat('Principal Paid', CalculationUtils.formatCurrency(principalPaid))),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Outstanding Principal', style: TextStyle(color: Colors.white, fontSize: 12)),
                  Text(
                    CalculationUtils.formatCurrency(_loan.pendingPrincipal),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    );
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
