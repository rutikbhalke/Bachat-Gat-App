import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../providers/bachat_gat_provider.dart';
import '../../models/member.dart';
import '../../models/loan.dart';
import '../../models/monthly_contribution.dart';
import '../../app/app_colors.dart';
import '../../core/utils/calculation_utils.dart';
import '../../services/pdf_service.dart';
import '../../services/share_service.dart';
import '../../l10n/app_localizations.dart';

class MemberDetailScreen extends StatefulWidget {
  final Member member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  late Member _member;
  late Stream<List<MonthlyContribution>> _contributionsStream;
  late Stream<List<Loan>> _loansStream;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    // Cache streams in initState to prevent rebuild loops
    final provider = Provider.of<BachatGatProvider>(context, listen: false);
    _contributionsStream = provider.watchContributions(memberId: _member.id);
    _loansStream = provider.watchLoans(memberId: _member.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BachatGatProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Profile'),
        actions: [
          IconButton(
            onPressed: () => _showReportDialog(provider, l10n),
            icon: const Icon(Icons.description_outlined),
            tooltip: l10n.generateReceipt,
          ),
          IconButton(
            onPressed: () => _editMember(provider),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () => _deactivateMember(provider),
            icon: const Icon(Icons.person_remove_outlined),
            tooltip: 'Deactivate Member',
          ),
        ],
      ),
      body: StreamBuilder<List<MonthlyContribution>>(
        stream: _contributionsStream,
        builder: (context, contributionSnapshot) {
          final contributions = contributionSnapshot.data ?? [];
          contributions.sort((a, b) => b.year != a.year ? b.year.compareTo(a.year) : b.month.compareTo(a.month));
          
          final totalInvested = contributions.fold<double>(0.0, (sum, i) => sum + i.paidAmount);

          return StreamBuilder<List<Loan>>(
            stream: _loansStream,
            builder: (context, loanSnapshot) {
              final loans = loanSnapshot.data ?? [];
              final outstandingLoan = loans.where((l) => l.status == LoanStatus.active)
                  .fold<double>(0.0, (sum, l) => sum + l.pendingPrincipal);

              return SingleChildScrollView(
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
                          'Current: ${CalculationUtils.formatCurrency(_member.monthlyContribution)}/mo',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (contributions.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No history found')))
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: contributions.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final inv = contributions[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${CalculationUtils.getMonthName(inv.month)} ${inv.year}'),
                            subtitle: Text(
                              inv.status.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: inv.status == ContributionStatus.paid ? AppColors.success : AppColors.accent,
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
              );
            }
          );
        }
      ),
    );
  }

  void _showReportDialog(BachatGatProvider provider, AppLocalizations l10n) {
    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.generateReceipt),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedMonth,
                items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(CalculationUtils.getMonthName(i + 1)))),
                onChanged: (val) => setDialogState(() => selectedMonth = val!),
                decoration: InputDecoration(labelText: l10n.month),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: selectedYear,
                items: [now.year - 1, now.year, now.year + 1].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (val) => setDialogState(() => selectedYear = val!),
                decoration: const InputDecoration(labelText: 'Year'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    _generateAndActionReceipt(provider, l10n, selectedMonth, selectedYear, isShare: false);
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(l10n.view),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(120, 40)),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    _generateAndActionReceipt(provider, l10n, selectedMonth, selectedYear, isShare: true);
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: Text(l10n.shareOnWhatsApp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 40),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndActionReceipt(BachatGatProvider provider, AppLocalizations l10n, int month, int year, {required bool isShare}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final report = await provider.getMemberReport(_member, month, year);
      final group = await provider.watchGroup().first;
      
      final labels = {
        'groupName': group?.name ?? 'Bachat Gat',
        'monthlyReceipt': l10n.monthlyReceipt,
        'member': l10n.member,
        'phone': l10n.phone,
        'month': l10n.month,
        'monthlyContribution': l10n.monthlyContribution,
        'regularHafta': l10n.regularHafta,
        'amountPaid': l10n.amountPaid,
        'pending': l10n.pending,
        'loan': l10n.loan,
        'openingLoan': l10n.openingLoan,
        'interestRate': l10n.interestRate,
        'monthlyInterest': l10n.monthlyInterest,
        'loanRepaid': l10n.loanRepaid,
        'closingLoan': l10n.closingLoan,
        'total': l10n.total,
        'totalPaid': l10n.totalPaid,
      };

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/BG_Receipt_${_member.name}_${month}_$year.pdf';
      
      final file = await PdfService.generateMemberReceipt(
        report: report,
        labels: labels,
        filePath: filePath,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (isShare) {
        await ShareService.shareMemberReceipt(
          report: report,
          filePath: file.path,
          languageCode: l10n.localeName,
        );
      } else {
        await Printing.layoutPdf(onLayout: (format) async => file.readAsBytes());
      }
      
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _editMember(BachatGatProvider provider) {
    final nameController = TextEditingController(text: _member.name);
    final phoneController = TextEditingController(text: _member.phone);
    final amountController = TextEditingController(text: _member.monthlyContribution.toString());

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
                monthlyContribution: double.tryParse(amountController.text) ?? _member.monthlyContribution,
                updatedAt: DateTime.now(),
              );
              
              await provider.updateMember(newMember);
              if (!context.mounted) return;
              setState(() => _member = newMember);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deactivateMember(BachatGatProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Member'),
        content: Text('Are you sure you want to deactivate ${_member.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              await provider.deactivateMember(_member.id);
              if (!context.mounted) return;
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to members list
            },
            child: const Text('Deactivate'),
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
