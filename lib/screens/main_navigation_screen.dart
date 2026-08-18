import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/bachat_gat_provider.dart';
import '../app/app_colors.dart';
import '../models/member.dart';
import '../models/loan.dart';
import '../models/monthly_contribution.dart';
import '../models/transaction.dart';
import '../models/loan_repayment.dart';
import '../core/utils/calculation_utils.dart';
import 'dashboard/dashboard_screen.dart';
import 'members/members_screen.dart';
import 'loans/loans_screen.dart';
import 'reports/reports_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const DashboardScreen(),
      const MembersScreen(),
      const SizedBox.shrink(), // Center button placeholder
      const LoansScreen(),
      const ReportsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BachatGatProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _showAddMenu(provider);
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_rounded),
            label: l10n.members,
          ),
          const BottomNavigationBarItem(
            icon: SizedBox.shrink(),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_rounded),
            label: l10n.loans,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.grid_view_rounded),
            label: l10n.reports,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(provider),
        elevation: 4,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 36),
      ),
    );
  }

  void _showAddMenu(BachatGatProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.quickActions, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAddOption(
                    icon: Icons.person_add_rounded,
                    label: '${l10n.members} +',
                    color: AppColors.info,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddMemberDialog(provider);
                    },
                  ),
                  _buildAddOption(
                    icon: Icons.savings_rounded,
                    label: l10n.addSavings,
                    color: AppColors.success,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddInvestmentDialog(provider);
                    },
                  ),
                  _buildAddOption(
                    icon: Icons.upload_rounded,
                    label: l10n.loans,
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.pop(context);
                      _showGiveLoanDialog(provider);
                    },
                  ),
                  _buildAddOption(
                    icon: Icons.download_rounded,
                    label: l10n.loanRepaid,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _showRepaymentDialog(provider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showAddMemberDialog(BachatGatProvider provider) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController(text: '1000');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Monthly Investment (₹)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final now = DateTime.now();
                await provider.addMember(Member(
                  id: 'M_${now.millisecondsSinceEpoch}',
                  groupId: provider.groupId,
                  name: nameController.text,
                  phone: phoneController.text,
                  joinDate: now,
                  monthlyContribution: double.tryParse(amountController.text) ?? 1000.0,
                  createdAt: now,
                  updatedAt: now,
                ));
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddInvestmentDialog(BachatGatProvider provider) {
    provider.watchMembers().first.then((members) {
      if (!mounted) return;
      if (members.isEmpty) {
        _showError('Please add a member first');
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

  void _showGiveLoanDialog(BachatGatProvider provider) {
    provider.watchMembers().first.then((members) async {
      if (!mounted) return;
      if (members.isEmpty) {
        _showError('Please add a member first');
        return;
      }

      final group = await provider.watchGroup().first;
      final totalSavings = group?.totalSavings ?? 0.0;
      final totalOutstandingLoans = group?.totalOutstandingLoans ?? 0.0;
      final availableFund = CalculationUtils.calculateAvailableFund(
        totalSavings: totalSavings,
        outstandingLoans: totalOutstandingLoans,
      );

      if (availableFund <= 0) {
        if (!mounted) return;
        _showError('No available group fund for a new loan.');
        return;
      }

      Member? selectedMember;
      final amountController = TextEditingController();
      final rateController = TextEditingController(text: '2.0');
      final purposeController = TextEditingController();
      String? amountErrorMessage;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            void validateAmount(String val) {
              final parsed = double.tryParse(val);
              if (parsed == null || parsed <= 0) {
                amountErrorMessage = 'Please enter a valid loan amount';
              } else if (parsed > availableFund) {
                amountErrorMessage = 'Available group fund is ${CalculationUtils.formatCurrency(availableFund)}. Maximum loan amount allowed is ${CalculationUtils.formatCurrency(availableFund)}.';
              } else {
                amountErrorMessage = null;
              }
              setDialogState(() {});
            }

            return AlertDialog(
              title: const Text('Give Loan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Available for Lending', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                Text(
                                  CalculationUtils.formatCurrency(availableFund),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Member>(
                      items: members.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                      onChanged: (val) => setDialogState(() => selectedMember = val),
                      decoration: const InputDecoration(labelText: 'Select Member'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: 'Loan Amount (₹)',
                        errorText: amountErrorMessage,
                        helperText: 'Max allowed: ${CalculationUtils.formatCurrency(availableFund)}',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: validateAmount,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rateController,
                      decoration: const InputDecoration(labelText: 'Monthly Interest Rate (%)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: purposeController,
                      decoration: const InputDecoration(labelText: 'Purpose (optional)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedMember == null) {
                      _showError('Please select a member');
                      return;
                    }
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      setDialogState(() {
                        amountErrorMessage = 'Please enter a valid loan amount';
                      });
                      return;
                    }
                    if (amount > availableFund) {
                      setDialogState(() {
                        amountErrorMessage = 'Available group fund is ${CalculationUtils.formatCurrency(availableFund)}. Maximum loan amount allowed is ${CalculationUtils.formatCurrency(availableFund)}.';
                      });
                      return;
                    }

                    try {
                      final now = DateTime.now();
                      final loan = Loan(
                        id: 'L_${now.millisecondsSinceEpoch}',
                        groupId: provider.groupId,
                        memberId: selectedMember!.id,
                        originalPrincipal: amount,
                        pendingPrincipal: amount,
                        interestRate: double.tryParse(rateController.text) ?? 2.0,
                        loanDate: now,
                        purpose: purposeController.text,
                        status: LoanStatus.active,
                        createdAt: now,
                        updatedAt: now,
                      );

                      final tx = AppTransaction(
                        id: 'T_${now.millisecondsSinceEpoch}',
                        memberId: selectedMember!.id,
                        memberName: selectedMember!.name,
                        type: TransactionType.loanIssue,
                        amount: amount,
                        date: now,
                        description: 'Loan Issued: ₹$amount to ${selectedMember!.name}',
                        referenceId: loan.id,
                      );

                      await provider.issueLoan(loan, tx);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                    } catch (e) {
                      if (!dialogContext.mounted) return;
                      _showError(e.toString().replaceAll('Exception: ', ''));
                    }
                  },
                  child: const Text('Issue'),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  void _showRepaymentDialog(BachatGatProvider provider) {
    provider.watchLoans().first.then((loans) {
      if (!mounted) return;
      final activeLoans = loans.where((l) => l.status == LoanStatus.active).toList();
      if (activeLoans.isEmpty) {
        _showError('No active loans found');
        return;
      }

      provider.watchMembers().first.then((membersList) {
        if (!mounted) return;
        final membersMap = {for (var m in membersList) m.id: m};
        Loan? selectedLoan;
        final principalController = TextEditingController(text: '0');
        final haftaController = TextEditingController(text: '1000');
        final now = DateTime.now();
        int selectedMonth = now.month;
        int selectedYear = now.year;

        showDialog(
          context: context,
          builder: (dialogContext) => StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              final interestAmount = selectedLoan != null
                  ? CalculationUtils.calculateMonthlyInterest(
                      outstandingPrincipal: selectedLoan!.pendingPrincipal,
                      annualRate: selectedLoan!.interestRate,
                    )
                  : 0.0;
              final principalRepaid = double.tryParse(principalController.text) ?? 0.0;
              final regularHafta = double.tryParse(haftaController.text) ?? 0.0;
              final totalPayment = regularHafta + interestAmount + principalRepaid;

              return AlertDialog(
                title: const Text('Record Loan Repayment'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<Loan>(
                        items: activeLoans.map((l) => DropdownMenuItem(value: l, child: Text('${membersMap[l.memberId]?.name ?? l.memberId}: ₹${l.pendingPrincipal.toStringAsFixed(0)}'))).toList(),
                        onChanged: (val) {
                          selectedLoan = val;
                          if (val != null) {
                            final m = membersMap[val.memberId];
                            if (m != null) {
                              haftaController.text = m.monthlyContribution.toStringAsFixed(0);
                            }
                          }
                          setDialogState(() {});
                        },
                        decoration: const InputDecoration(labelText: 'Select Active Loan'),
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
                      if (selectedLoan != null) ...[
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
                              Text('Pending: ₹${selectedLoan!.pendingPrincipal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('Interest (2%): ₹${interestAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.interest, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: haftaController,
                        decoration: const InputDecoration(labelText: 'Regular Hafta Amount (₹)'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: principalController,
                        decoration: const InputDecoration(labelText: 'Principal Repayment Amount (₹)'),
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
                      if (selectedLoan != null && totalPayment > 0) {
                        if (principalRepaid > selectedLoan!.pendingPrincipal) {
                          _showError('Principal repayment cannot exceed pending principal');
                          return;
                        }

                        final recordDate = DateTime.now();
                        final periodSuffix = '${selectedYear}_${selectedMonth.toString().padLeft(2, '0')}';
                        final newClosing = selectedLoan!.pendingPrincipal - principalRepaid > 0
                            ? selectedLoan!.pendingPrincipal - principalRepaid
                            : 0.0;

                        final repayment = LoanRepayment(
                          id: 'R_${selectedLoan!.id}_$periodSuffix',
                          loanId: selectedLoan!.id,
                          groupId: provider.groupId,
                          memberId: selectedLoan!.memberId,
                          month: selectedMonth,
                          year: selectedYear,
                          openingPrincipal: selectedLoan!.pendingPrincipal,
                          interestRate: selectedLoan!.interestRate,
                          interestAmount: interestAmount,
                          regularContribution: regularHafta,
                          principalRepaid: principalRepaid,
                          totalPaid: totalPayment,
                          closingPrincipal: newClosing,
                          paymentDate: recordDate,
                          createdAt: recordDate,
                          updatedAt: recordDate,
                        );

                        final contribution = MonthlyContribution(
                          id: 'C_${selectedLoan!.memberId}_$periodSuffix',
                          memberId: selectedLoan!.memberId,
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
                        );

                        final memberName = membersMap[selectedLoan!.memberId]?.name ?? 'Member';
                        final tx = AppTransaction(
                          id: 'T_${selectedLoan!.memberId}_$periodSuffix',
                          memberId: selectedLoan!.memberId,
                          memberName: memberName,
                          type: TransactionType.loanRepayment,
                          amount: totalPayment,
                          date: recordDate,
                          description: 'Repayment - ${CalculationUtils.getMonthName(selectedMonth)} $selectedYear (Hafta: ₹$regularHafta, Interest: ₹$interestAmount, Principal: ₹$principalRepaid)',
                          referenceId: selectedLoan!.id,
                        );

                        await provider.recordLoanRepayment(
                          loan: selectedLoan!,
                          repayment: repayment,
                          tx: tx,
                          contribution: contribution,
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
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildAddOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
