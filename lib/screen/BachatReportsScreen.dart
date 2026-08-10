import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/bachat_models.dart';
import '../utils/bachat_storage_service.dart';
import '../utils/whatsapp_service.dart';

class BachatReportsScreen extends StatefulWidget {
  @override
  _BachatReportsScreenState createState() => _BachatReportsScreenState();
}

class _BachatReportsScreenState extends State<BachatReportsScreen>
    with SingleTickerProviderStateMixin {
  final BachatStorageService _storage = BachatStorageService();
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 0,
  );

  String? _selectedMemberId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _storage.init().then((_) {
      if (!mounted) return;
      setState(() {
        if (_storage.members.isNotEmpty) {
          _selectedMemberId = _storage.members.first.id;
        }
      });
    });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Color(0xFF1B5E20),
        title: Text('Reports',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber[400],
          indicatorWeight: 3,
          labelColor: Colors.amber[300],
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Group'),
            Tab(text: 'Member'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupReportView(),
          _buildMemberReportView(),
        ],
      ),
    );
  }

  Widget _buildGroupReportView() {
    if (_storage.groups.isEmpty) {
      return Center(child: Text('No Bachat Gat group available.'));
    }

    final group = _storage.groups.first;
    final members = _storage.getMembersForGroup(group.id);
    final totalSavings = _storage.getTotalSavingsForGroup(group.id);
    final totalInterest = _storage.getTotalInterestEarnedForGroup(group.id);
    final totalLoansDisbursed =
        _storage.getTotalLoansDisbursedForGroup(group.id);
    final activeLoansBal =
        _storage.getTotalActiveLoanPrincipalForGroup(group.id);
    final netAvailable = _storage.getNetAvailableGroupFunds(group.id);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20)),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('${members.length} Members',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  SizedBox(height: 14),
                  Divider(height: 1),
                  SizedBox(height: 14),
                  _buildReportRow('Savings Collected',
                      _currencyFormat.format(totalSavings), Colors.green[800]!),
                  _buildReportRow('Interest Earned',
                      _currencyFormat.format(totalInterest), Colors.blue[800]!),
                  _buildReportRow(
                      'Loans Disbursed',
                      _currencyFormat.format(totalLoansDisbursed),
                      Colors.orange[800]!),
                  _buildReportRow('Active Loan Pending',
                      _currencyFormat.format(activeLoansBal), Colors.red[800]!),
                  Divider(height: 20),
                  _buildReportRow('Net Cash Pool',
                      _currencyFormat.format(netAvailable), Color(0xFF1B5E20),
                      isBold: true),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(Icons.share),
              label: Text('Share WhatsApp',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                final text = WhatsAppService.buildGroupReportText(group: group);
                WhatsAppService.sendWhatsAppMessage(
                  phoneNumber: members.isNotEmpty ? members.first.phone : '',
                  messageText: text,
                );
              },
            ),
          ),
          SizedBox(height: 24),
          Text('Member Financial Summaries',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800])),
          SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: members.length,
            itemBuilder: (ctx, idx) {
              final member = members[idx];
              final memberSavings =
                  _storage.getTotalSavingsForMember(member.id);
              final activeLoan = _storage.getActiveLoanForMember(member.id);

              return Card(
                margin: EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(member.name,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                      'Role: ${member.role} | Savings: ${_currencyFormat.format(memberSavings)}',
                      overflow: TextOverflow.ellipsis),
                  trailing: SizedBox(
                    width: 92,
                    child: Text(
                      activeLoan != null
                          ? _currencyFormat
                              .format(activeLoan.remainingPrincipal)
                          : 'No Loan',
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: activeLoan != null
                              ? Colors.orange[900]
                              : Colors.green[800],
                          fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemberReportView() {
    if (_storage.members.isEmpty || _storage.groups.isEmpty) {
      return Center(child: Text('No members available for reporting.'));
    }

    final member = _storage.members.firstWhere(
      (m) => m.id == _selectedMemberId,
      orElse: () => _storage.members.first,
    );
    final group = _storage.groups.first;
    final totalSavings = _storage.getTotalSavingsForMember(member.id);
    final totalInterest = _storage.getTotalInterestPaidByMember(member.id);
    final totalPrincipalPaid =
        _storage.getTotalPrincipalPaidByMember(member.id);
    final activeLoan = _storage.getActiveLoanForMember(member.id);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Member',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey[700])),
          SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: member.id,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.person, color: Color(0xFF1B5E20)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
            items: _storage.members.map((m) {
              return DropdownMenuItem(
                  value: m.id,
                  child: Text('${m.name} (${m.phone})',
                      overflow: TextOverflow.ellipsis));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedMemberId = val);
            },
          ),
          SizedBox(height: 16),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20)),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(member.role,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[900])),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('Group: ${group.name}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('Phone: ${member.phone}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  SizedBox(height: 14),
                  Divider(height: 1),
                  SizedBox(height: 14),
                  _buildReportRow('Savings',
                      _currencyFormat.format(totalSavings), Colors.green[800]!),
                  _buildReportRow('Interest Paid',
                      _currencyFormat.format(totalInterest), Colors.blue[800]!),
                  _buildReportRow(
                      'Principal Repaid',
                      _currencyFormat.format(totalPrincipalPaid),
                      Colors.teal[800]!),
                  if (activeLoan != null)
                    _buildReportRow(
                        'Outstanding Loan',
                        _currencyFormat.format(activeLoan.remainingPrincipal),
                        Colors.red[800]!,
                        isBold: true)
                  else
                    _buildReportRow('Active Loan', 'Rs 0', Colors.grey[700]!),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(Icons.message),
              label: Text('Send WhatsApp',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                final text = WhatsAppService.buildMemberStatementText(
                    group: group, member: member);
                WhatsAppService.sendWhatsAppMessage(
                    phoneNumber: member.phone, messageText: text);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value, Color color,
      {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isBold ? 14 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.grey[800],
              ),
            ),
          ),
          SizedBox(width: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isBold ? 15 : 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
