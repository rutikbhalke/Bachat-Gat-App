import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/bachat_models.dart';
import '../utils/bachat_storage_service.dart';

class BachatDisburseLoanScreen extends StatefulWidget {
  final String? initialGroupId;
  final String? initialMemberId;

  const BachatDisburseLoanScreen({
    Key? key,
    this.initialGroupId,
    this.initialMemberId,
  }) : super(key: key);

  @override
  _BachatDisburseLoanScreenState createState() => _BachatDisburseLoanScreenState();
}

class _BachatDisburseLoanScreenState extends State<BachatDisburseLoanScreen> {
  final BachatStorageService _storage = BachatStorageService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  String? _selectedGroupId;
  String? _selectedMemberId;
  final _principalController = TextEditingController(text: '10000');
  final _interestRateController = TextEditingController(text: '2.0');
  final _purposeController = TextEditingController(text: 'Personal / Business Loan');

  double _calculatedMonthlyInterest = 200.0;

  @override
  void initState() {
    super.initState();
    _storage.init().then((_) {
      if (!mounted) return;
      setState(() {
        if (_storage.groups.isNotEmpty) {
          _selectedGroupId = widget.initialGroupId ?? _storage.groups.first.id;
          final groupMembers = _storage.getMembersForGroup(_selectedGroupId!);
          if (groupMembers.isNotEmpty) {
            _selectedMemberId = widget.initialMemberId ?? groupMembers.first.id;
          }
        }
        _updateCalculatedInterest();
      });
    });
    _principalController.addListener(_updateCalculatedInterest);
    _interestRateController.addListener(_updateCalculatedInterest);
  }

  @override
  void dispose() {
    _principalController.dispose();
    _interestRateController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  void _updateCalculatedInterest() {
    final principal = double.tryParse(_principalController.text) ?? 0.0;
    final rate = double.tryParse(_interestRateController.text) ?? 2.0;
    setState(() {
      _calculatedMonthlyInterest = principal * (rate / 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    final members = _selectedGroupId != null
        ? _storage.getMembersForGroup(_selectedGroupId!)
        : <BachatMember>[];

    return Scaffold(
      backgroundColor: Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.orange[800],
        title: Text('Disburse Loan from Group', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions Card
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[900]),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Loans are disbursed from the Bachat Gat combined savings pool. Monthly interest (fixed 2%) will be calculated on the remaining loan principal.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Form Container
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group Selector
                    Text('Select Bachat Gat Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                    SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedGroupId,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.groups, color: Color(0xFF1B5E20)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _storage.groups.map((g) {
                        return DropdownMenuItem(value: g.id, child: Text(g.name));
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedGroupId = val;
                          final groupMembers = _storage.getMembersForGroup(val!);
                          _selectedMemberId = groupMembers.isNotEmpty ? groupMembers.first.id : null;
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    // Member Selector
                    Text('Select Borrower Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                    SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _selectedMemberId,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person, color: Color(0xFF1B5E20)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: members.map((m) {
                        final activeLoan = _storage.getActiveLoanForMember(m.id);
                        final loanNotice = activeLoan != null ? ' (Active Loan Exists)' : '';
                        return DropdownMenuItem(value: m.id, child: Text('${m.name}$loanNotice'));
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedMemberId = val);
                      },
                    ),
                    SizedBox(height: 16),

                    // Loan Principal Input
                    Text('Loan Principal Amount (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                    SizedBox(height: 6),
                    TextField(
                      controller: _principalController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.currency_rupee, color: Colors.green[800]),
                        hintText: 'e.g. 10000',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Monthly Interest Rate (Default 2%)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Monthly Interest Rate (%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                              SizedBox(height: 6),
                              TextField(
                                controller: _interestRateController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.percent, color: Colors.blue[800]),
                                  hintText: '2.0',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Auto Calculated Interest Banner
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Calculated Monthly Interest (2%)', style: TextStyle(fontSize: 11, color: Colors.blue[900])),
                              Text(
                                _currencyFormat.format(_calculatedMonthlyInterest),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                              ),
                            ],
                          ),
                          Icon(Icons.calculate, color: Colors.blue[900], size: 28),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // Purpose / Notes
                    Text('Loan Purpose / Remarks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700])),
                    SizedBox(height: 6),
                    TextField(
                      controller: _purposeController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.note, color: Colors.grey[700]),
                        hintText: 'e.g. Small business setup / Emergency',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(Icons.check_circle),
                        label: Text('Disburse Loan Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () async {
                          if (_selectedGroupId == null || _selectedMemberId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please select a group and member')),
                            );
                            return;
                          }

                          final principal = double.tryParse(_principalController.text) ?? 0.0;
                          final rate = double.tryParse(_interestRateController.text) ?? 2.0;

                          if (principal <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please enter a valid loan principal amount')),
                            );
                            return;
                          }

                          await _storage.disburseLoan(
                            groupId: _selectedGroupId!,
                            memberId: _selectedMemberId!,
                            principalAmount: principal,
                            interestRateMonthly: rate,
                            purpose: _purposeController.text.trim(),
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Loan disbursed successfully! 💸')),
                          );

                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
