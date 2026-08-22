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
import '../widgets/common/searchable_member_picker.dart';

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
                    label: l10n.loanRepayment,
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

  void _showAddMemberDialog(BachatGatProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    final group = await provider.watchGroup().first;
    final defaultPerShare = group?.monthlyContributionAmount ?? 1000.0;

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final sharesController = TextEditingController(text: '1');
    final perShareController = TextEditingController(text: defaultPerShare.toStringAsFixed(0));
    bool isSubmitting = false;
    String? errorMessage;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final shares = int.tryParse(sharesController.text) ?? 1;
          final perShare = double.tryParse(perShareController.text) ?? defaultPerShare;
          final totalMonthly = CalculationUtils.calculateMemberMonthlyHafta(
            shares: shares,
            contributionPerShare: perShare,
          );

          return AlertDialog(
            title: Text(l10n.addMember),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                          const SizedBox(width: 6),
                          Expanded(child: Text(errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 12))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(labelText: l10n.fullName),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(labelText: l10n.phoneNumber),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sharesController,
                          decoration: InputDecoration(labelText: l10n.sharesCount),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setDialogState(() => errorMessage = null),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: perShareController,
                          decoration: InputDecoration(labelText: '${l10n.perShare} (₹)'),
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setDialogState(() => errorMessage = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${l10n.monthlyContribution}:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(
                          CalculationUtils.formatCurrency(totalMonthly),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty) {
                          setDialogState(() => errorMessage = l10n.noMembersFound); // Closest one, or just hardcode if missing
                          return;
                        }
                        final parsedShares = int.tryParse(sharesController.text);
                        if (parsedShares == null || parsedShares < 1) {
                          setDialogState(() => errorMessage = 'Shares must be at least 1.');
                          return;
                        }
                        final parsedPerShare = double.tryParse(perShareController.text);
                        if (parsedPerShare == null || parsedPerShare < 0) {
                          setDialogState(() => errorMessage = 'Contribution per share must be valid.');
                          return;
                        }

                        setDialogState(() => isSubmitting = true);

                        try {
                          final now = DateTime.now();
                          final member = Member(
                            id: 'M_${now.millisecondsSinceEpoch}',
                            groupId: provider.groupId,
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            joinDate: now,
                            shares: parsedShares,
                            monthlyContributionPerShare: parsedPerShare,
                            monthlyContribution: parsedShares * parsedPerShare,
                            createdAt: now,
                            updatedAt: now,
                          );

                          await provider.addMember(member);
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            errorMessage = e.toString().replaceAll('Exception: ', '');
                          });
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(l10n.record),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddInvestmentDialog(BachatGatProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    provider.watchMembers().first.then((members) {
      if (!mounted) return;
      if (members.isEmpty) {
        _showError('Please add a member first');
        return;
      }

      Member? selectedMember;
      Loan? memberActiveLoan;
      String memberSearchQuery = '';
      final haftaController = TextEditingController();
      final principalController = TextEditingController(text: '0');
      final now = DateTime.now();
      final activeCycle = CalculationUtils.getActiveCycleForDate(now, dueDay: 10);
      int selectedMonth = activeCycle.month;
      int selectedYear = activeCycle.year;
      double calculatedInterest = 0.0;
      bool isSubmitting = false;

      showDialog(
        context: context,
        builder: (dialogContext) => StreamBuilder<List<MonthlyContribution>>(
          stream: provider.watchContributions(),
          builder: (dialogContext, contribSnapshot) {
            return StatefulBuilder(
              builder: (dialogContext, setDialogState) {
                final contributions = contribSnapshot.data ?? [];

                // Map contributions for selectedMonth & selectedYear
                final currentMonthContribsByMember = <String, MonthlyContribution>{};
                for (final c in contributions) {
                  if (c.month == selectedMonth && c.year == selectedYear) {
                    currentMonthContribsByMember[c.memberId] = c;
                  }
                }

                // Compute pending amounts for all active members
                final pendingAmounts = <String, double>{};
                final pendingMembers = <Member>[];

                for (final member in members) {
                  if (member.status != MemberStatus.active) continue;
                  final contrib = currentMonthContribsByMember[member.id];
                  final remaining = CalculationUtils.calculateMemberPendingHafta(
                    member: member,
                    contribution: contrib,
                  );

                  if (remaining > 0) {
                    pendingAmounts[member.id] = remaining;
                    pendingMembers.add(member);
                  }
                }

                // Ensure selectedMember is valid and in pending list
                if (selectedMember != null) {
                  final matching = pendingMembers.where((m) => m.id == selectedMember!.id).toList();
                  if (matching.isEmpty) {
                    selectedMember = null;
                    memberActiveLoan = null;
                    calculatedInterest = 0.0;
                    haftaController.clear();
                  } else {
                    selectedMember = matching.first;
                  }
                }

                // Filter pending members based on search query
                final searchedPendingMembers = pendingMembers.where((m) {
                  if (memberSearchQuery.isEmpty) return true;
                  final query = memberSearchQuery.toLowerCase();
                  final cleanPhone = m.phone.replaceAll(RegExp(r'\D'), '');
                  return m.name.toLowerCase().contains(query) ||
                      cleanPhone.contains(query);
                }).toList();

                final sortedSearched = CalculationUtils.sortMembersByBaseNameAndSequence(searchedPendingMembers);
                final dropdownMembers = List<Member>.from(sortedSearched);
                if (selectedMember != null &&
                    !dropdownMembers.any((m) => m.id == selectedMember!.id) &&
                    pendingMembers.any((m) => m.id == selectedMember!.id)) {
                  dropdownMembers.insert(0, selectedMember!);
                }

                final hafta = double.tryParse(haftaController.text) ?? 0.0;
                final principal = double.tryParse(principalController.text) ?? 0.0;
                final totalCalculated = hafta + calculatedInterest + principal;

                return AlertDialog(
                  title: Text(l10n.recordMonthlyCollection),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Searchable Member Selector Field with Modal Search List
                        InkWell(
                          onTap: pendingMembers.isEmpty
                              ? null
                              : () async {
                                  final picked = await SearchableMemberPicker.show(
                                    context: context,
                                    pendingMembers: pendingMembers,
                                    pendingAmounts: pendingAmounts,
                                    initiallySelected: selectedMember,
                                  );
                                  if (picked != null) {
                                    selectedMember = picked;
                                    final remaining = pendingAmounts[picked.id] ?? picked.monthlyContribution;
                                    haftaController.text = remaining.toStringAsFixed(0);
                                    final loans = await provider.watchLoans(memberId: picked.id).first;
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
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.selectMember,
                              hintText: l10n.searchMembers,
                              prefixIcon: const Icon(Icons.person_search_rounded, size: 22, color: AppColors.primary),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selectedMember != null)
                                    IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        setDialogState(() {
                                          selectedMember = null;
                                          memberActiveLoan = null;
                                          calculatedInterest = 0.0;
                                          haftaController.clear();
                                        });
                                      },
                                    ),
                                  const Icon(Icons.arrow_drop_down_rounded, size: 24, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                ],
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            child: Text(
                              selectedMember != null
                                  ? '${selectedMember!.name} (₹${(pendingAmounts[selectedMember!.id] ?? selectedMember!.monthlyContribution).toStringAsFixed(0)})'
                                  : (pendingMembers.isEmpty
                                      ? l10n.allCollectionsUpToDate
                                      : l10n.searchMembers),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: selectedMember != null ? FontWeight.bold : FontWeight.normal,
                                color: selectedMember != null ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: selectedMonth,
                                items: List.generate(
                                  12,
                                  (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text(CalculationUtils.getMonthName(i + 1, locale: l10n.localeName)),
                                  ),
                                ),
                                onChanged: (val) {
                                  if (val != null && val != selectedMonth) {
                                    setDialogState(() {
                                      selectedMonth = val;
                                      selectedMember = null;
                                      memberActiveLoan = null;
                                      calculatedInterest = 0.0;
                                      haftaController.clear();
                                    });
                                  }
                                },
                                decoration: InputDecoration(labelText: l10n.month),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: selectedYear,
                                items: [now.year - 1, now.year, now.year + 1]
                                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null && val != selectedYear) {
                                    setDialogState(() {
                                      selectedYear = val;
                                      selectedMember = null;
                                      memberActiveLoan = null;
                                      calculatedInterest = 0.0;
                                      haftaController.clear();
                                    });
                                  }
                                },
                                decoration: InputDecoration(labelText: l10n.year),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: haftaController,
                          decoration: InputDecoration(labelText: l10n.regularHaftaLabel),
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
                              '${l10n.activeLoan}: ₹${memberActiveLoan!.pendingPrincipal.toStringAsFixed(0)} @ ${memberActiveLoan!.interestRate}%/${l10n.perMonth}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${l10n.interestDue}: ₹${calculatedInterest.toStringAsFixed(0)}',
                              style: const TextStyle(color: AppColors.interest, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: principalController,
                        decoration: InputDecoration(labelText: l10n.loanPrincipalRepaymentOptional),
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
                          Text(l10n.totalPaymentLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (selectedMember == null) {
                            _showError(l10n.selectMember);
                            return;
                          }
                          if (hafta <= 0 && principal <= 0) {
                            _showError(l10n.totalPayment); 
                            return;
                          }
                          if (hafta < 0 || principal < 0) {
                            _showError(l10n.totalPayment); 
                            return;
                          }
                          final maxAllowedHafta = pendingAmounts[selectedMember!.id] ?? selectedMember!.monthlyContribution;
                          if (hafta > maxAllowedHafta) {
                            _showError('${l10n.regularHafta} cannot exceed remaining pending amount (₹${maxAllowedHafta.toStringAsFixed(0)})');
                            return;
                          }
                          if (memberActiveLoan != null && principal > memberActiveLoan!.pendingPrincipal) {
                            _showError(l10n.principalCannotExceedPending);
                            return;
                          }

                            setDialogState(() => isSubmitting = true);

                            try {
                              final recordDate = DateTime.now();
                              final docId = MonthlyContribution.generateId(
                                memberId: selectedMember!.id,
                                month: selectedMonth,
                                year: selectedYear,
                              );
                              
                              LoanRepayment? repayment;
                              if (memberActiveLoan != null) {
                                repayment = LoanRepayment(
                                  id: 'R_${memberActiveLoan!.id}_${selectedYear}_${selectedMonth.toString().padLeft(2, '0')}',
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
                                id: docId,
                                memberId: selectedMember!.id,
                                groupId: provider.groupId,
                                month: selectedMonth,
                                year: selectedYear,
                                regularHaftaAmount: selectedMember!.monthlyContribution,
                                interestAmount: calculatedInterest,
                                loanPrincipalPaid: principal,
                                totalPaid: totalCalculated,
                                expectedAmount: selectedMember!.monthlyContribution,
                                paidAmount: hafta,
                                status: hafta >= selectedMember!.monthlyContribution
                                    ? ContributionStatus.paid
                                    : (hafta > 0 ? ContributionStatus.partial : ContributionStatus.pending),
                                paymentDate: recordDate,
                                createdAt: recordDate,
                                updatedAt: recordDate,
                              );

                              final txId = 'T_${selectedMember!.id}_${selectedYear}_${selectedMonth.toString().padLeft(2, '0')}_${recordDate.millisecondsSinceEpoch}';
                              final tx = AppTransaction(
                                id: txId,
                                memberId: selectedMember!.id,
                                memberName: selectedMember!.name,
                                type: memberActiveLoan != null ? TransactionType.loanRepayment : TransactionType.monthlyInvestment,
                                amount: totalCalculated,
                                date: recordDate,
                                description: memberActiveLoan != null
                                    ? 'Monthly Payment - ${CalculationUtils.getMonthName(selectedMonth, locale: l10n.localeName)} $selectedYear (Hafta: ₹$hafta, Interest: ₹$calculatedInterest, Principal: ₹$principal)'
                                    : 'Monthly Contribution - ${CalculationUtils.getMonthName(selectedMonth, locale: l10n.localeName)} $selectedYear',
                              );

                              await provider.recordContribution(
                                contribution,
                                tx,
                                loan: memberActiveLoan,
                                repayment: repayment,
                              );

                              if (!dialogContext.mounted) return;
                              Navigator.pop(dialogContext);
                            } catch (e) {
                              setDialogState(() => isSubmitting = false);
                              _showError(e.toString().replaceAll('Exception: ', ''));
                            }
                          },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.record),
                ),
              ],
            );
          },
        );
      },
    ),
  );
});
}

  void _showGiveLoanDialog(BachatGatProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    provider.watchMembers().first.then((members) async {
      if (!mounted) return;
      if (members.isEmpty) {
        _showError('Please add a member first');
        return;
      }

      final group = await provider.watchGroup().first;
      final availableFund = group?.availableFund ?? 0.0;

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
      bool isSubmitting = false;

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
                amountErrorMessage = l10n.availableBalance; // Use a better message if available
              } else {
                amountErrorMessage = null;
              }
              setDialogState(() {});
            }

            return AlertDialog(
              title: Text(l10n.createLoan),
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
                                Text(l10n.availableForLending, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
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
                      decoration: InputDecoration(labelText: l10n.selectMember),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      decoration: InputDecoration(
                        labelText: l10n.loanAmountLabel,
                        errorText: amountErrorMessage,
                        helperText: '${l10n.maxAllowed}: ${CalculationUtils.formatCurrency(availableFund)}',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: validateAmount,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rateController,
                      decoration: InputDecoration(labelText: l10n.monthlyInterestRatePercent),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: purposeController,
                      decoration: InputDecoration(labelText: l10n.purposeOptional),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (selectedMember == null) {
                            _showError(l10n.selectMember);
                            return;
                          }
                          final amount = double.tryParse(amountController.text);
                          if (amount == null || amount <= 0) {
                            setDialogState(() {
                              amountErrorMessage = l10n.loanAmount;
                            });
                            return;
                          }
                          if (amount > availableFund) {
                            setDialogState(() {
                              amountErrorMessage = l10n.availableBalance;
                            });
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

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
                              description: 'Loan Issued: ₹${amount.toStringAsFixed(0)} to ${selectedMember!.name}',
                              referenceId: loan.id,
                            );

                            await provider.issueLoan(loan, tx);
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            _showError(e.toString().replaceAll('Exception: ', ''));
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.record),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  void _showRepaymentDialog(BachatGatProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    provider.watchLoans().first.then((loans) {
      if (!mounted) return;
      final activeLoans = loans.where((l) => l.status == LoanStatus.active).toList();
      if (activeLoans.isEmpty) {
        _showError(l10n.noLoansFound);
        return;
      }

      provider.watchMembers().first.then((membersList) {
        if (!mounted) return;
        final membersMap = {for (var m in membersList) m.id: m};
        Loan? selectedLoan;
        final principalController = TextEditingController(text: '0');
        final haftaController = TextEditingController(text: '0');
        final now = DateTime.now();
        int selectedMonth = now.month;
        int selectedYear = now.year;
        bool isSubmitting = false;

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
                title: Text(l10n.recordLoanPayment),
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
                        decoration: InputDecoration(labelText: l10n.selectActiveLoan),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: selectedMonth,
                              items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(CalculationUtils.getMonthName(i + 1, locale: l10n.localeName)))),
                              onChanged: (val) => setDialogState(() => selectedMonth = val!),
                              decoration: InputDecoration(labelText: l10n.month),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: selectedYear,
                              items: [now.year - 1, now.year, now.year + 1].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                              onChanged: (val) => setDialogState(() => selectedYear = val!),
                              decoration: InputDecoration(labelText: l10n.year),
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
                              Text('${l10n.outstanding}: ₹${selectedLoan!.pendingPrincipal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text('${l10n.interest}: ₹${interestAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.interest, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        controller: haftaController,
                        decoration: InputDecoration(labelText: l10n.regularHaftaAmountLabel),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: principalController,
                        decoration: InputDecoration(labelText: l10n.principalRepaymentAmount),
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
                            Text(l10n.totalPaymentLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  TextButton(
                    onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                    child: Text(l10n.cancel),
                  ),
                  ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (selectedLoan != null && totalPayment > 0) {
                              if (principalRepaid > selectedLoan!.pendingPrincipal) {
                                _showError(l10n.principalCannotExceedPending);
                                return;
                              }

                              setDialogState(() => isSubmitting = true);

                              try {
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

                                final docId = MonthlyContribution.generateId(
                                  memberId: selectedLoan!.memberId,
                                  month: selectedMonth,
                                  year: selectedYear,
                                );

                                final contribution = regularHafta > 0
                                    ? MonthlyContribution(
                                        id: docId,
                                        memberId: selectedLoan!.memberId,
                                        groupId: provider.groupId,
                                        month: selectedMonth,
                                        year: selectedYear,
                                        regularHaftaAmount: membersMap[selectedLoan!.memberId]?.monthlyContribution ?? regularHafta,
                                        interestAmount: interestAmount,
                                        loanPrincipalPaid: principalRepaid,
                                        totalPaid: totalPayment,
                                        expectedAmount: membersMap[selectedLoan!.memberId]?.monthlyContribution ?? regularHafta,
                                        paidAmount: regularHafta,
                                        status: regularHafta >= (membersMap[selectedLoan!.memberId]?.monthlyContribution ?? regularHafta) ? ContributionStatus.paid : ContributionStatus.partial,
                                        paymentDate: recordDate,
                                        createdAt: recordDate,
                                        updatedAt: recordDate,
                                      )
                                    : null;

                                final memberName = membersMap[selectedLoan!.memberId]?.name ?? 'Member';
                                final txId = 'T_${selectedLoan!.memberId}_${periodSuffix}_${recordDate.millisecondsSinceEpoch}';
                                final tx = AppTransaction(
                                  id: txId,
                                  memberId: selectedLoan!.memberId,
                                  memberName: memberName,
                                  type: TransactionType.loanRepayment,
                                  amount: totalPayment,
                                  date: recordDate,
                                  description: 'Repayment - ${CalculationUtils.getMonthName(selectedMonth, locale: l10n.localeName)} $selectedYear (Hafta: ₹$regularHafta, Interest: ₹$interestAmount, Principal: ₹$principalRepaid)',
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
                              } catch (e) {
                                setDialogState(() => isSubmitting = false);
                                _showError(e.toString().replaceAll('Exception: ', ''));
                              }
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(l10n.record),
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
