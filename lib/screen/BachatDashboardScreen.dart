import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/bachat_models.dart';
import '../utils/bachat_storage_service.dart';
import '../utils/whatsapp_service.dart';
import 'BachatDisburseLoanScreen.dart';
import 'BachatGroupDetailScreen.dart';
import 'BachatRecordPaymentScreen.dart';
import 'BachatReportsScreen.dart';
import 'BachatSettingsScreen.dart';

class BachatDashboardScreen extends StatefulWidget {
  @override
  _BachatDashboardScreenState createState() => _BachatDashboardScreenState();
}

class _BachatDashboardScreenState extends State<BachatDashboardScreen> {
  final BachatStorageService _storage = BachatStorageService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _storage.init().then((_) {
      if (mounted) setState(() {});
    });
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

  void _showAddMemberDialog() {
    if (_storage.groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bachat Gat group is not ready yet')),
      );
      return;
    }

    final group = _storage.groups.first;
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRole = 'Member';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.person_add, color: Color(0xFF1B5E20)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Add Member',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    group.name,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Member Full Name *',
                    hintText: 'e.g. Sunil Patil',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Mobile / WhatsApp Number *',
                    hintText: 'e.g. 9876543210',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Group Role',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Please fill name and phone number')),
                  );
                  return;
                }

                await _storage.addMember(
                  groupId: group.id,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  role: selectedRole,
                );

                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Member added successfully')),
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
    final group = _storage.groups.isNotEmpty ? _storage.groups.first : null;
    final groupId = group?.id;
    final savings =
        groupId == null ? 0.0 : _storage.getTotalSavingsForGroup(groupId);
    final interest = groupId == null
        ? 0.0
        : _storage.getTotalInterestEarnedForGroup(groupId);
    final activeLoans = groupId == null
        ? 0.0
        : _storage.getTotalActiveLoanPrincipalForGroup(groupId);
    final netCash =
        groupId == null ? 0.0 : _storage.getNetAvailableGroupFunds(groupId);

    return Scaffold(
      backgroundColor: Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Color(0xFF1B5E20),
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.account_balance, color: Color(0xFFFFD54F), size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group?.name ?? 'Bachat Gat',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white),
                  ),
                  Text(
                    'Single group manager',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.green[100]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BachatSettingsScreen()));
            },
          ),
          IconButton(
            icon: Icon(Icons.analytics_outlined, color: Colors.white),
            tooltip: 'Reports',
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => BachatReportsScreen()));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverallSummaryCard(
                savings: savings,
                interest: interest,
                activeLoans: activeLoans,
                netCash: netCash,
                group: group,
              ),
              SizedBox(height: 20),
              Text('Actions',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800])),
              SizedBox(height: 12),
              _buildQuickActionsGrid(),
              SizedBox(height: 24),
              Text('Bachat Gat Details',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800])),
              SizedBox(height: 8),
              if (group == null)
                _buildEmptyGroupView()
              else
                _buildGroupCard(group),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Color(0xFF1B5E20),
        icon: Icon(Icons.add_card, color: Colors.white),
        label: Text('Payment',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => BachatRecordPaymentScreen()));
        },
      ),
    );
  }

  Widget _buildOverallSummaryCard({
    required double savings,
    required double interest,
    required double activeLoans,
    required double netCash,
    required BachatGroup? group,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Color(0xFF1B5E20).withOpacity(0.25),
              blurRadius: 12,
              offset: Offset(0, 6)),
        ],
      ),
      padding: EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TOTAL SAVINGS POOL',
                  style: TextStyle(
                      color: Colors.green[100],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1),
                ),
              ),
              if (group != null)
                Text(
                  '${_currencyFormat.format(group.monthlyContribution)} / mo',
                  style: TextStyle(
                      color: Colors.amber[100],
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
            ],
          ),
          SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _currencyFormat.format(savings),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16),
          Divider(color: Colors.white24, height: 1),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildSummaryMetric(Icons.trending_up, 'Interest',
                      _currencyFormat.format(interest), Color(0xFFFFD54F))),
              Expanded(
                  child: _buildSummaryMetric(
                      Icons.account_balance_wallet,
                      'Loans',
                      _currencyFormat.format(activeLoans),
                      Colors.orange[200]!)),
              Expanded(
                  child: _buildSummaryMetric(
                      Icons.account_balance,
                      'Net Cash',
                      _currencyFormat.format(netCash),
                      Colors.lightGreenAccent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 10)),
        SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return Row(
      children: [
        Expanded(
            child: _buildActionTile(Icons.person_add_outlined, 'Add Member',
                Colors.blue[700]!, _showAddMemberDialog)),
        SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
              Icons.price_change_outlined, 'Loan', Colors.orange[800]!, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => BachatDisburseLoanScreen()));
          }),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
              Icons.assessment_outlined, 'Reports', Colors.purple[700]!, () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => BachatReportsScreen()));
          }),
        ),
      ],
    );
  }

  Widget _buildActionTile(
      IconData icon, String title, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(BachatGroup group) {
    final members = _storage.getMembersForGroup(group.id);
    final savings = _storage.getTotalSavingsForGroup(group.id);
    final interest = _storage.getTotalInterestEarnedForGroup(group.id);
    final activeLoans = _storage.getTotalActiveLoanPrincipalForGroup(group.id);
    final netPool = _storage.getNetAvailableGroupFunds(group.id);

    return Card(
      margin: EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => BachatGroupDetailScreen(groupId: group.id)));
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFF1B5E20).withOpacity(0.15),
                    child: Icon(Icons.groups, color: Color(0xFF1B5E20)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[900])),
                        SizedBox(height: 2),
                        Text(
                            '${members.length} members | Formed ${DateFormat('MMM yyyy').format(group.formationDate)}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.share, color: Colors.green[800]),
                    tooltip: 'Share report',
                    onPressed: () {
                      final text =
                          WhatsAppService.buildGroupReportText(group: group);
                      WhatsAppService.sendWhatsAppMessage(
                        phoneNumber:
                            members.isNotEmpty ? members.first.phone : '',
                        messageText: text,
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 14),
              Divider(height: 1),
              SizedBox(height: 14),
              Wrap(
                runSpacing: 12,
                spacing: 12,
                children: [
                  _buildCardMetric('Savings', _currencyFormat.format(savings),
                      Colors.green[800]!),
                  _buildCardMetric('Loans', _currencyFormat.format(activeLoans),
                      Colors.orange[800]!),
                  _buildCardMetric('Interest', _currencyFormat.format(interest),
                      Colors.blue[800]!),
                  _buildCardMetric('Net Pool', _currencyFormat.format(netPool),
                      Colors.purple[800]!),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Monthly contribution: ${_currencyFormat.format(group.monthlyContribution)}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[900]),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('View',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20))),
                  Icon(Icons.chevron_right, size: 18, color: Color(0xFF1B5E20)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardMetric(String label, String value, Color color) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGroupView() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(Icons.group_off_outlined, size: 48, color: Colors.grey[400]),
          SizedBox(height: 12),
          Text('Bachat Gat group is loading',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700])),
          SizedBox(height: 6),
          Text('The app is set up for one group only.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        ],
      ),
    );
  }
}
