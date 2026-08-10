import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/bachat_models.dart';
import '../utils/bachat_storage_service.dart';
import '../utils/whatsapp_service.dart';
import 'BachatMemberDetailScreen.dart';
import 'BachatDisburseLoanScreen.dart';
import 'BachatRecordPaymentScreen.dart';

class BachatGroupDetailScreen extends StatefulWidget {
  final String groupId;

  const BachatGroupDetailScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _BachatGroupDetailScreenState createState() => _BachatGroupDetailScreenState();
}

class _BachatGroupDetailScreenState extends State<BachatGroupDetailScreen>
    with SingleTickerProviderStateMixin {
  final BachatStorageService _storage = BachatStorageService();
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _storage.addListener(_onStorageChanged);
  }

  @override
  void dispose() {
    _storage.removeListener(_onStorageChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onStorageChanged() {
    if (mounted) setState(() {});
  }

  void _showAddMemberDialog(BachatGroup group) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'Member';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFF1B5E20)),
              SizedBox(width: 8),
              Text('Add Member to ${group.name}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Member Full Name *',
                    hintText: 'e.g. Sunita Patil',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'WhatsApp Mobile Number *',
                    hintText: 'e.g. 9876543210',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: ['Member', 'President', 'Secretary', 'Treasurer']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameController.text.trim().isEmpty || phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill Name and Phone number')),
                  );
                  return;
                }

                await _storage.addMember(
                  groupId: group.id,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  role: selectedRole,
                );

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Member added to group! 👤')),
                );
              },
              child: Text('Add Member'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    BachatGroup group;
    try {
      group = _storage.groups.firstWhere((g) => g.id == widget.groupId);
    } catch (_) {
      return Scaffold(
        appBar: AppBar(title: Text('Group Not Found')),
        body: Center(child: Text('Group could not be located.')),
      );
    }

    final members = _storage.getMembersForGroup(group.id);
    final loans = _storage.getLoansForGroup(group.id);
    final payments = _storage.getPaymentsForGroup(group.id);

    final totalSavings = _storage.getTotalSavingsForGroup(group.id);
    final totalInterest = _storage.getTotalInterestEarnedForGroup(group.id);
    final activeLoansBal = _storage.getTotalActiveLoanPrincipalForGroup(group.id);
    final netAvailable = _storage.getNetAvailableGroupFunds(group.id);

    return Scaffold(
      backgroundColor: Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Color(0xFF1B5E20),
        elevation: 0,
        title: Text(
          group.name,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            tooltip: 'Share Group Summary via WhatsApp',
            onPressed: () {
              final text = WhatsAppService.buildGroupReportText(group: group);
              WhatsAppService.sendWhatsAppMessage(
                phoneNumber: members.isNotEmpty ? members.first.phone : '',
                messageText: text,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber[400],
          indicatorWeight: 3,
          labelColor: Colors.amber[300],
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Members (${members.length})'),
            Tab(text: 'Loans (${loans.length})'),
            Tab(text: 'Ledger (${payments.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Group Financial Header Banner
          _buildGroupHeaderBanner(
            group: group,
            totalSavings: totalSavings,
            totalInterest: totalInterest,
            activeLoansBal: activeLoansBal,
            netAvailable: netAvailable,
          ),

          // Tab Content Area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMembersTab(group, members),
                _buildLoansTab(group, loans),
                _buildLedgerTab(payments),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_add_member',
            backgroundColor: Colors.blue[800],
            child: Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Add Member',
            onPressed: () => _showAddMemberDialog(group),
          ),
          SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'fab_record_payment',
            backgroundColor: Color(0xFF1B5E20),
            icon: Icon(Icons.payment, color: Colors.white),
            label: Text('Record Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BachatRecordPaymentScreen(initialGroupId: group.id),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeaderBanner({
    required BachatGroup group,
    required double totalSavings,
    required double totalInterest,
    required double activeLoansBal,
    required double netAvailable,
  }) {
    return Container(
      color: Color(0xFF1B5E20),
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        padding: EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AVAILABLE NET CASH POOL',
                      style: TextStyle(color: Colors.green[100], fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _currencyFormat.format(netAvailable),
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber[700],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text('Fixed Contribution', style: TextStyle(color: Colors.white, fontSize: 9)),
                      Text('₹${group.monthlyContribution.toInt()}/mo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Divider(color: Colors.white24, height: 1),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderMiniMetric('Savings Pool', _currencyFormat.format(totalSavings)),
                _buildHeaderMiniMetric('2% Interest', _currencyFormat.format(totalInterest)),
                _buildHeaderMiniMetric('Active Loans', _currencyFormat.format(activeLoansBal)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMiniMetric(String title, String val) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.white70, fontSize: 10)),
        SizedBox(height: 2),
        Text(val, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildMembersTab(BachatGroup group, List<BachatMember> members) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_outlined, size: 48, color: Colors.grey[400]),
            SizedBox(height: 12),
            Text('No Members in this Group Yet', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1B5E20), foregroundColor: Colors.white),
              onPressed: () => _showAddMemberDialog(group),
              icon: Icon(Icons.person_add),
              label: Text('Add First Member'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: members.length,
      itemBuilder: (ctx, idx) {
        final member = members[idx];
        final memberSavings = _storage.getTotalSavingsForMember(member.id);
        final activeLoan = _storage.getActiveLoanForMember(member.id);

        return Card(
          margin: EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: Color(0xFF1B5E20).withOpacity(0.1),
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    member.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (member.role != 'Member')
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      member.role,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('Phone: ${member.phone}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Savings: ${_currencyFormat.format(memberSavings)}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green[800]),
                    ),
                    if (activeLoan != null) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Loan Bal: ${_currencyFormat.format(activeLoan.remainingPrincipal)}',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.message, color: Colors.green[700]),
              tooltip: 'Send WhatsApp Statement',
              onPressed: () {
                final text = WhatsAppService.buildMemberStatementText(
                  group: group,
                  member: member,
                );
                WhatsAppService.sendWhatsAppMessage(
                  phoneNumber: member.phone,
                  messageText: text,
                );
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BachatMemberDetailScreen(
                    memberId: member.id,
                    groupId: group.id,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoansTab(BachatGroup group, List<BachatLoan> loans) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Loan Records (${loans.length})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BachatDisburseLoanScreen(initialGroupId: group.id),
                    ),
                  );
                },
                icon: Icon(Icons.add, size: 18),
                label: Text('Give Loan'),
              ),
            ],
          ),
        ),
        Expanded(
          child: loans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.price_change_outlined, size: 48, color: Colors.grey[400]),
                      SizedBox(height: 12),
                      Text('No Loans Issued in this Group', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: loans.length,
                  itemBuilder: (ctx, idx) {
                    final loan = loans[idx];
                    final isPaidOff = loan.status == 'PAID_OFF';
                    final monthlyInterest = (loan.remainingPrincipal * (loan.interestRateMonthly / 100));

                    return Card(
                      margin: EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.person, color: Color(0xFF1B5E20), size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      loan.memberName,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isPaidOff ? Colors.green[100] : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isPaidOff ? 'PAID OFF' : 'ACTIVE LOAN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isPaidOff ? Colors.green[900] : Colors.orange[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Original Amount', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                    Text(_currencyFormat.format(loan.principalAmount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Remaining Principal', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                    Text(
                                      _currencyFormat.format(loan.remainingPrincipal),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isPaidOff ? Colors.green[800] : Colors.orange[800],
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('2% Monthly Int.', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                    Text(_currencyFormat.format(monthlyInterest), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue[800])),
                                  ],
                                ),
                              ],
                            ),
                            if (loan.purpose.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text('Purpose: ${loan.purpose}', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLedgerTab(List<MonthlyPayment> payments) {
    if (payments.isEmpty) {
      return Center(
        child: Text('No payment entries recorded yet.', style: TextStyle(color: Colors.grey[600])),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: payments.length,
      itemBuilder: (ctx, idx) {
        final p = payments[idx];
        final dateStr = DateFormat('dd MMM yyyy').format(p.paymentDate);

        return Card(
          margin: EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.memberName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(p.monthYear, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 12)),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Savings: ${_currencyFormat.format(p.savingsAmount)}', style: TextStyle(fontSize: 12, color: Colors.green[800])),
                    if (p.interestPaid > 0)
                      Text('2% Interest: ${_currencyFormat.format(p.interestPaid)}', style: TextStyle(fontSize: 12, color: Colors.blue[800])),
                    if (p.principalPaid > 0)
                      Text('Principal Paid: ${_currencyFormat.format(p.principalPaid)}', style: TextStyle(fontSize: 12, color: Colors.orange[800])),
                  ],
                ),
                SizedBox(height: 6),
                Divider(height: 1),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Paid: ${_currencyFormat.format(p.totalPaid)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    if (p.remainingLoanPrincipal > 0)
                      Text('Loan Bal: ${_currencyFormat.format(p.remainingLoanPrincipal)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red[800]))
                    else
                      Text('Date: $dateStr', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
