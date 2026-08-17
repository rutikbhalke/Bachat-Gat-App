import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bachat_gat_provider.dart';
import '../../models/loan.dart';
import '../../models/loan_repayment.dart';
import '../../models/monthly_contribution.dart';
import '../../models/transaction.dart';
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
    final provider = Provider.of<BachatGatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Details'),
        actions: [
          if (_loan.status == LoanStatus.active)
            IconButton(
              onPressed: () => _showRepaymentDialog(provider),
              icon: const Icon(Icons.payment_rounded),
              tooltip: 'Record Payment',
            ),
        ],
      ),
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
                  Text('CURRENT MONTH INTEREST (2%)', style: Theme.of(context).textTheme.labelLarge),
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
                        const Text('Monthly Interest due:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          CalculationUtils.formatCurrency(currentInterest),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.accent, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('REPAYMENT HISTORY', style: Theme.of(context).textTheme.labelLarge),
                    Text('${repayments.length} Payments', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 12),
                if (repayments.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No repayments recorded yet')))
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
                                Text(
                                  '${CalculationUtils.getMonthName(r.month)} ${r.year} (${CalculationUtils.formatShortDate(r.paymentDate)})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  CalculationUtils.formatCurrency(r.totalPaid),
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.success, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _miniBadge('Interest: ${CalculationUtils.formatCurrency(r.interestAmount)}', AppColors.interest),
                                const SizedBox(width: 8),
                                _miniBadge('Principal: ${CalculationUtils.formatCurrency(r.principalRepaid)}', AppColors.primary),
                                if (r.regularContribution > 0) ...[
                                  const SizedBox(width: 8),
                                  _miniBadge('Hafta: ${CalculationUtils.formatCurrency(r.regularContribution)}', AppColors.success),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Closing Balance: ${CalculationUtils.formatCurrency(r.closingPrincipal)}',
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
                _miniStat('Monthly Rate', '${_loan.interestRate}% / mo'),
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

  void _showRepaymentDialog(BachatGatProvider provider) {
    final principalController = TextEditingController(text: '0');
    final haftaController = TextEditingController(text: '0');
    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final interestAmount = CalculationUtils.calculateMonthlyInterest(
            outstandingPrincipal: _loan.pendingPrincipal,
            annualRate: _loan.interestRate,
          );
          final principalRepaid = double.tryParse(principalController.text) ?? 0.0;
          final regularHafta = double.tryParse(haftaController.text) ?? 0.0;
          final totalPayment = regularHafta + interestAmount + principalRepaid;

          return AlertDialog(
            title: const Text('Record Loan Payment'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pending: ₹${_loan.pendingPrincipal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text('Interest (2%): ₹${interestAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.interest, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: principalController,
                    decoration: const InputDecoration(labelText: 'Principal Repayment Amount (₹)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: haftaController,
                    decoration: const InputDecoration(labelText: 'Regular Hafta (Optional) (₹)'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                  ),
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
                          CalculationUtils.formatCurrency(totalPayment),
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
                  if (totalPayment > 0) {
                    if (principalRepaid > _loan.pendingPrincipal) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Principal repayment cannot exceed pending principal')));
                      return;
                    }

                    final recordDate = DateTime.now();
                    final periodSuffix = '${selectedYear}_${selectedMonth.toString().padLeft(2, '0')}';
                    final newClosing = _loan.pendingPrincipal - principalRepaid > 0
                        ? _loan.pendingPrincipal - principalRepaid
                        : 0.0;

                    final repayment = LoanRepayment(
                      id: 'R_${_loan.id}_$periodSuffix',
                      loanId: _loan.id,
                      groupId: provider.groupId,
                      memberId: _loan.memberId,
                      month: selectedMonth,
                      year: selectedYear,
                      openingPrincipal: _loan.pendingPrincipal,
                      interestRate: _loan.interestRate,
                      interestAmount: interestAmount,
                      regularContribution: regularHafta,
                      principalRepaid: principalRepaid,
                      totalPaid: totalPayment,
                      closingPrincipal: newClosing,
                      paymentDate: recordDate,
                      createdAt: recordDate,
                      updatedAt: recordDate,
                    );

                    final contribution = regularHafta > 0
                        ? MonthlyContribution(
                            id: 'C_${_loan.memberId}_$periodSuffix',
                            memberId: _loan.memberId,
                            groupId: provider.groupId,
                            month: selectedMonth,
                            year: selectedYear,
                            regularHaftaAmount: regularHafta,
                            interestAmount: interestAmount,
                            loanPrincipalPaid: principalRepaid,
                            totalPaid: totalPayment,
                            expectedAmount: regularHafta,
                            paidAmount: totalPayment,
                            status: ContributionStatus.paid,
                            paymentDate: recordDate,
                            createdAt: recordDate,
                            updatedAt: recordDate,
                          )
                        : null;

                    final tx = AppTransaction(
                      id: 'T_${_loan.memberId}_$periodSuffix',
                      memberId: _loan.memberId,
                      memberName: 'Member',
                      type: TransactionType.loanRepayment,
                      amount: totalPayment,
                      date: recordDate,
                      description: 'Loan Repayment - ${CalculationUtils.getMonthName(selectedMonth)} $selectedYear (Interest: ₹$interestAmount, Principal: ₹$principalRepaid)',
                      referenceId: _loan.id,
                    );

                    await provider.recordLoanRepayment(
                      loan: _loan,
                      repayment: repayment,
                      tx: tx,
                      contribution: contribution,
                    );

                    setState(() {
                      _loan = _loan.copyWith(
                        pendingPrincipal: newClosing,
                        status: newClosing <= 0 ? LoanStatus.closed : LoanStatus.active,
                      );
                    });

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
