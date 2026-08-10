import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/bachat_models.dart';
import '../utils/bachat_storage_service.dart';
import '../utils/whatsapp_service.dart';
import 'BachatRecordPaymentScreen.dart';

class BachatMemberDetailScreen extends StatefulWidget {
  final String memberId;
  final String groupId;

  const BachatMemberDetailScreen({
    Key? key,
    required this.memberId,
    required this.groupId,
  }) : super(key: key);

  @override
  _BachatMemberDetailScreenState createState() => _BachatMemberDetailScreenState();
}

class _BachatMemberDetailScreenState extends State<BachatMemberDetailScreen> {
  final BachatStorageService _storage = BachatStorageService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _storage.addListener(_onStorageChanged);
  }

  @override
  void dispose() {
    _storage.removeListener(_onStorageChanged);
    super.dispose();
  }

  void _onStorageChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    BachatMember member;
    BachatGroup group;
    try {
      member = _storage.members.firstWhere((m) => m.id == widget.memberId);
      group = _storage.groups.firstWhere((g) => g.id == widget.groupId);
    } catch (_) {
      return Scaffold(
        appBar: AppBar(title: Text('Member Not Found')),
        body: Center(child: Text('Member details could not be found.')),
      );
    }

    final totalSavings = _storage.getTotalSavingsForMember(member.id);
    final totalInterest = _storage.getTotalInterestPaidByMember(member.id);
    final totalPrincipalPaid = _storage.getTotalPrincipalPaidByMember(member.id);
    final activeLoan = _storage.getActiveLoanForMember(member.id);
    final payments = _storage.getPaymentsForMember(member.id);

    return Scaffold(
      backgroundColor: Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Color(0xFF1B5E20),
        title: Text(member.name, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.message, color: Colors.amber[300]),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Member Info Header Card
            _buildProfileCard(member, group),
            SizedBox(height: 16),

            // Financial Summary Metrics Grid
            _buildFinancialGrid(
              totalSavings: totalSavings,
              totalInterest: totalInterest,
              totalPrincipalPaid: totalPrincipalPaid,
              activeLoan: activeLoan,
            ),
            SizedBox(height: 20),

            // Active Loan Card (if exists)
            if (activeLoan != null) ...[
              Text('Active Loan Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              SizedBox(height: 8),
              _buildActiveLoanCard(activeLoan),
              SizedBox(height: 20),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(Icons.chat),
                    label: Text('WhatsApp Statement', style: TextStyle(fontWeight: FontWeight.bold)),
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
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(Icons.payment),
                    label: Text('Record Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BachatRecordPaymentScreen(
                            initialGroupId: group.id,
                            initialMemberId: member.id,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Payment Ledger History
            Text('Payment History (${payments.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
            SizedBox(height: 10),

            if (payments.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text('No payment records for this member yet.')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: payments.length,
                itemBuilder: (ctx, idx) {
                  final p = payments[idx];
                  return _buildPaymentHistoryCard(p, group, member);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BachatMember member, BachatGroup group) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFF1B5E20),
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : 'M',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.name,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          member.role,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('Group: ${group.name}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  SizedBox(height: 2),
                  Text('Phone: ${member.phone}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  SizedBox(height: 2),
                  Text(
                    'Joined: ${DateFormat('dd MMM yyyy').format(member.joiningDate)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialGrid({
    required double totalSavings,
    required double totalInterest,
    required double totalPrincipalPaid,
    required BachatLoan? activeLoan,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _buildMetricBox('Total Savings', _currencyFormat.format(totalSavings), Icons.savings, Colors.green[800]!),
        _buildMetricBox('2% Interest Paid', _currencyFormat.format(totalInterest), Icons.percent, Colors.blue[800]!),
        _buildMetricBox('Loan Principal Repaid', _currencyFormat.format(totalPrincipalPaid), Icons.account_balance_wallet, Colors.teal[800]!),
        _buildMetricBox(
          'Active Loan Bal',
          activeLoan != null ? _currencyFormat.format(activeLoan.remainingPrincipal) : '₹0',
          Icons.error_outline,
          activeLoan != null ? Colors.orange[900]! : Colors.grey[600]!,
        ),
      ],
    );
  }

  Widget _buildMetricBox(String title, String val, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                SizedBox(height: 2),
                Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLoanCard(BachatLoan loan) {
    final paidAmount = loan.principalAmount - loan.remainingPrincipal;
    final progress = (paidAmount / loan.principalAmount).clamp(0.0, 1.0);
    final monthlyInterest = loan.remainingPrincipal * (loan.interestRateMonthly / 100);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.amber[50],
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('LOAN AMOUNT TAKEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber[900])),
                Text(_currencyFormat.format(loan.principalAmount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber[900])),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Remaining Balance', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                    Text(_currencyFormat.format(loan.remainingPrincipal), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[800])),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Next Monthly 2% Interest', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                    Text(_currencyFormat.format(monthlyInterest), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.amber[200],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
              ),
            ),
            SizedBox(height: 6),
            Text(
              '${(progress * 100).toInt()}% Loan Principal Repaid (${_currencyFormat.format(paidAmount)} paid of ${_currencyFormat.format(loan.principalAmount)})',
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryCard(MonthlyPayment p, BachatGroup group, BachatMember member) {
    final dateStr = DateFormat('dd MMM yyyy').format(p.paymentDate);

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p.monthYear, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20))),
                Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Savings: ${_currencyFormat.format(p.savingsAmount)}', style: TextStyle(fontSize: 12, color: Colors.green[800])),
                if (p.interestPaid > 0)
                  Text('2% Int: ${_currencyFormat.format(p.interestPaid)}', style: TextStyle(fontSize: 12, color: Colors.blue[800])),
                if (p.principalPaid > 0)
                  Text('Loan Principal: ${_currencyFormat.format(p.principalPaid)}', style: TextStyle(fontSize: 12, color: Colors.orange[800])),
              ],
            ),
            SizedBox(height: 6),
            Divider(height: 1),
            SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Paid: ${_currencyFormat.format(p.totalPaid)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Icon(Icons.share, size: 18, color: Colors.green[800]),
                  tooltip: 'Share Receipt on WhatsApp',
                  onPressed: () {
                    final text = WhatsAppService.buildPaymentReceiptText(
                      group: group,
                      member: member,
                      payment: p,
                      totalMemberSavings: _storage.getTotalSavingsForMember(member.id),
                    );
                    WhatsAppService.sendWhatsAppMessage(
                      phoneNumber: member.phone,
                      messageText: text,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
