import 'package:flutter/material.dart';
import '../../services/data_service.dart';
import '../../models/member.dart';
import '../../models/loan.dart';
import '../../models/monthly_investment.dart';
import '../../app/app_colors.dart';
import '../../core/utils/calculation_utils.dart';

class MemberDetailScreen extends StatefulWidget {
  final DataService dataService;
  final Member member;

  const MemberDetailScreen({super.key, required this.dataService, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  late Member _member;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  @override
  Widget build(BuildContext context) {
    final investments = widget.dataService.getInvestments()
        .where((i) => i.memberId == _member.id)
        .toList()
      ..sort((a, b) => b.year != a.year ? b.year.compareTo(a.year) : b.month.compareTo(a.month));

    final totalInvested = investments.fold<double>(0.0, (sum, i) => sum + i.paidAmount);
    
    final loans = widget.dataService.getLoans().where((l) => l.memberId == _member.id).toList();
    final outstandingLoan = loans.where((l) => l.status == LoanStatus.active)
        .fold<double>(0.0, (sum, l) => sum + l.outstandingPrincipal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Profile'),
        actions: [
          IconButton(
            onPressed: _editMember,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      _member.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_member.name, style: Theme.of(context).textTheme.headlineMedium),
                  Text(_member.phone, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Joined ${CalculationUtils.formatShortDate(_member.joinDate)}',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // --- FINANCIAL SUMMARY ---
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(
                    label: 'Total Invested',
                    value: CalculationUtils.formatCurrency(totalInvested),
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTile(
                    label: 'Outstanding Loan',
                    value: CalculationUtils.formatCurrency(outstandingLoan),
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // --- INVESTMENT HISTORY ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('INVESTMENT HISTORY', style: Theme.of(context).textTheme.labelLarge),
                Text(
                  'Current: ${CalculationUtils.formatCurrency(_member.monthlyInvestment)}/mo',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (investments.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No history found')))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: investments.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final inv = investments[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${CalculationUtils.getMonthName(inv.month)} ${inv.year}'),
                    subtitle: Text(
                      inv.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: inv.status == InvestmentStatus.paid ? AppColors.success : AppColors.accent,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CalculationUtils.formatCurrency(inv.paidAmount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (inv.pendingAmount > 0)
                          Text(
                            'Pending: ${CalculationUtils.formatCurrency(inv.pendingAmount)}',
                            style: const TextStyle(fontSize: 10, color: AppColors.error),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _editMember() {
    final nameController = TextEditingController(text: _member.name);
    final phoneController = TextEditingController(text: _member.phone);
    final amountController = TextEditingController(text: _member.monthlyInvestment.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Monthly Investment (₹)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newMember = _member.copyWith(
                name: nameController.text,
                phone: phoneController.text,
                monthlyInvestment: double.tryParse(amountController.text) ?? _member.monthlyInvestment,
              );
              
              final members = widget.dataService.getMembers();
              final idx = members.indexWhere((m) => m.id == _member.id);
              if (idx != -1) {
                members[idx] = newMember;
                await widget.dataService.saveMembers(members);
                if (!context.mounted) return;
                setState(() => _member = newMember);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}
