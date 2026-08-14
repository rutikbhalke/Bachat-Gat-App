import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../app/app_colors.dart';
import '../models/member.dart';
import '../models/loan.dart';
import '../core/utils/calculation_utils.dart';
import 'dashboard/dashboard_screen.dart';
import 'members/members_screen.dart';
import 'loans/loans_screen.dart';
import 'reports/reports_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final DataService dataService;

  const MainNavigationScreen({
    super.key,
    required this.dataService,
  });

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
      MembersScreen(dataService: widget.dataService),
      const SizedBox.shrink(), // Center button placeholder
      LoansScreen(dataService: widget.dataService),
      ReportsScreen(dataService: widget.dataService),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 2) {
            _showAddMenu();
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: SizedBox.shrink(),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_rounded),
            label: 'Loans',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'More',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMenu,
        elevation: 4,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 36),
      ),
    );
  }

  void _showAddMenu() {
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
              Text('Record Transaction', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAddOption(
                    icon: Icons.person_add_rounded,
                    label: 'Add Member',
                    color: AppColors.info,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddMemberDialog();
                    },
                  ),
                  _buildAddOption(
                    icon: Icons.savings_rounded,
                    label: 'Collect Savings',
                    color: AppColors.success,
                    onTap: () {
                      Navigator.pop(context);
                      _showAddInvestmentDialog();
                    },
                  ),
                  _buildAddOption(
                    icon: Icons.upload_rounded,
                    label: 'Give Loan',
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.pop(context);
                      _showGiveLoanDialog();
                    },
                  ),
                  _buildAddOption(
                    icon: Icons.download_rounded,
                    label: 'Loan Repay',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(context);
                      _showRepaymentDialog();
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

  void _showAddMemberDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final amountController = TextEditingController(text: '1000');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await widget.dataService.addMember(Member(
                  id: 'M_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameController.text,
                  phone: phoneController.text,
                  joinDate: DateTime.now(),
                  monthlyInvestment: double.tryParse(amountController.text) ?? 1000.0,
                ));
                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddInvestmentDialog() {
    final members = widget.dataService.getMembers();
    if (members.isEmpty) {
      _showError('Please add a member first');
      return;
    }

    Member? selectedMember;
    final amountController = TextEditingController();
    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Investment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Member>(
                  items: members.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                  onChanged: (val) {
                    selectedMember = val;
                    if (val != null) amountController.text = val.monthlyInvestment.toString();
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
                TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Paid Amount (₹)'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (selectedMember != null && amountController.text.isNotEmpty) {
                  await widget.dataService.recordInvestment(
                    member: selectedMember!,
                    month: selectedMonth,
                    year: selectedYear,
                    amount: double.parse(amountController.text),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGiveLoanDialog() {
    final members = widget.dataService.getMembers();
    if (members.isEmpty) {
      _showError('Please add a member first');
      return;
    }

    Member? selectedMember;
    final amountController = TextEditingController();
    final rateController = TextEditingController(text: widget.dataService.getSettings().defaultInterestRate.toString());
    final purposeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Give Loan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Member>(
                items: members.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
                onChanged: (val) => selectedMember = val,
                decoration: const InputDecoration(labelText: 'Select Member'),
              ),
              const SizedBox(height: 12),
              TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Loan Amount (₹)'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: rateController, decoration: const InputDecoration(labelText: 'Monthly Interest Rate (%)'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: purposeController, decoration: const InputDecoration(labelText: 'Purpose (optional)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedMember != null && amountController.text.isNotEmpty) {
                await widget.dataService.issueLoan(
                  member: selectedMember!,
                  amount: double.parse(amountController.text),
                  rate: double.parse(rateController.text),
                  purpose: purposeController.text,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Issue'),
          ),
        ],
      ),
    );
  }

  void _showRepaymentDialog() {
    final loans = widget.dataService.getLoans().where((l) => l.status == LoanStatus.active).toList();
    if (loans.isEmpty) {
      _showError('No active loans found');
      return;
    }

    final members = {for (var m in widget.dataService.getMembers()) m.id: m.name};
    Loan? selectedLoan;
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Repayment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Loan>(
              items: loans.map((l) => DropdownMenuItem(value: l, child: Text('${members[l.memberId]}: ₹${l.outstandingPrincipal}'))).toList(),
              onChanged: (val) => selectedLoan = val,
              decoration: const InputDecoration(labelText: 'Select Active Loan'),
            ),
            const SizedBox(height: 12),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Repayment Amount (₹)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedLoan != null && amountController.text.isNotEmpty) {
                await widget.dataService.recordRepayment(
                  loan: selectedLoan!,
                  paymentAmount: double.parse(amountController.text),
                );
                if (!context.mounted) return;
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Record'),
          ),
        ],
      ),
    );
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }
}
