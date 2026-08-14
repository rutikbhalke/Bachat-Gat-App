import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../app/app_colors.dart';
import '../../core/utils/calculation_utils.dart';

class ReportsScreen extends StatelessWidget {
  final DataService dataService;

  const ReportsScreen({super.key, required this.dataService});

  @override
  Widget build(BuildContext context) {
    final totalSavings = dataService.getTotalSavings();
    final loansGiven = dataService.getLoans().fold<double>(0.0, (sum, l) => sum + l.loanAmount);
    final recovered = dataService.getRepayments().fold<double>(0.0, (sum, r) => sum + r.principalAmount);
    final interest = dataService.getTotalInterestEarned();
    final outstanding = dataService.getTotalOutstandingLoans();
    final available = totalSavings - loansGiven + recovered + interest;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Financial Reports'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GROUP SUMMARY', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 16),
            _buildReportItem(context, 'Total Group Savings', totalSavings, Icons.savings_rounded, AppColors.success),
            _buildReportItem(context, 'Total Loans Issued', loansGiven, Icons.upload_rounded, AppColors.loan),
            _buildReportItem(context, 'Principal Recovered', recovered, Icons.download_rounded, AppColors.info),
            _buildReportItem(context, 'Interest Earned', interest, Icons.percent_rounded, AppColors.interest),
            _buildReportItem(context, 'Outstanding Principal', outstanding, Icons.history_rounded, AppColors.error),
            _buildReportItem(context, 'Available Group Balance', available, Icons.account_balance_wallet_rounded, AppColors.primary),
            
            const SizedBox(height: 32),
            Text('MONTHLY PERFORMANCE', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 16),
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_rounded, size: 54, color: AppColors.primary.withValues(alpha: 0.2)),
                  const SizedBox(height: 12),
                  const Text('Savings Growth Chart', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Text('(Coming in next update)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
