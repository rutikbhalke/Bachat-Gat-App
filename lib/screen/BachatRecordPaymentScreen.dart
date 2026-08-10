import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/bachat_models.dart';
import '../utils/bachat_storage_service.dart';
import '../utils/whatsapp_service.dart';

class BachatRecordPaymentScreen extends StatefulWidget {
  final String? initialGroupId;
  final String? initialMemberId;

  const BachatRecordPaymentScreen({
    Key? key,
    this.initialGroupId,
    this.initialMemberId,
  }) : super(key: key);

  @override
  _BachatRecordPaymentScreenState createState() =>
      _BachatRecordPaymentScreenState();
}

class _BachatRecordPaymentScreenState extends State<BachatRecordPaymentScreen> {
  final BachatStorageService _storage = BachatStorageService();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs ',
    decimalDigits: 0,
  );

  String? _selectedGroupId;
  String? _selectedMemberId;
  late String _monthYearText;

  final _savingsController = TextEditingController(text: '1000');
  final _interestPaidController = TextEditingController(text: '0');
  final _principalPaidController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  double _currentLoanPrincipal = 0.0;
  double _calculatedInterestDue = 0.0;
  double _remainingLoanPrincipalAfterPayment = 0.0;
  double _totalAmountSubmitted = 1000.0;
  bool _hasActiveLoan = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _monthYearText = DateFormat('MMMM yyyy').format(DateTime.now());

    _storage.init().then((_) {
      if (!mounted) return;
      setState(() {
        if (_storage.groups.isNotEmpty) {
          _selectedGroupId = widget.initialGroupId ?? _storage.groups.first.id;
          final members = _storage.getMembersForGroup(_selectedGroupId!);
          if (members.isNotEmpty) {
            _selectedMemberId = widget.initialMemberId ?? members.first.id;
          }
        }
        _updateLoanDetailsAndTotals();
      });
    });

    _savingsController.addListener(_recalculateTotals);
    _interestPaidController.addListener(_recalculateTotals);
    _principalPaidController.addListener(_recalculateTotals);
  }

  @override
  void dispose() {
    _savingsController.dispose();
    _interestPaidController.dispose();
    _principalPaidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateLoanDetailsAndTotals() {
    if (_selectedMemberId == null) {
      _hasActiveLoan = false;
      _currentLoanPrincipal = 0.0;
      _calculatedInterestDue = 0.0;
      _recalculateTotals();
      return;
    }

    final activeLoan = _storage.getActiveLoanForMember(_selectedMemberId!);
    if (activeLoan != null) {
      _hasActiveLoan = true;
      _currentLoanPrincipal = activeLoan.remainingPrincipal;
      _calculatedInterestDue =
          _currentLoanPrincipal * (activeLoan.interestRateMonthly / 100);
      _interestPaidController.text = _calculatedInterestDue.toInt().toString();
    } else {
      _hasActiveLoan = false;
      _currentLoanPrincipal = 0.0;
      _calculatedInterestDue = 0.0;
      _interestPaidController.text = '0';
      _principalPaidController.text = '0';
    }

    _recalculateTotals();
  }

  void _recalculateTotals() {
    if (!mounted) return;
    final savings = double.tryParse(_savingsController.text) ?? 0.0;
    final interest = double.tryParse(_interestPaidController.text) ?? 0.0;
    final principalPaid = double.tryParse(_principalPaidController.text) ?? 0.0;

    setState(() {
      _totalAmountSubmitted = savings + interest + principalPaid;
      _remainingLoanPrincipalAfterPayment = _hasActiveLoan
          ? (_currentLoanPrincipal - principalPaid).clamp(0.0, double.infinity)
          : 0.0;
    });
  }

  Future<void> _savePayment({required bool shareOnWhatsApp}) async {
    if (_selectedGroupId == null || _selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a member')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final group = _storage.groups.firstWhere((g) => g.id == _selectedGroupId);
    final member =
        _storage.members.firstWhere((m) => m.id == _selectedMemberId);
    final payment = await _storage.recordPayment(
      groupId: _selectedGroupId!,
      memberId: _selectedMemberId!,
      monthYear: _monthYearText.trim().isEmpty
          ? DateFormat('MMMM yyyy').format(DateTime.now())
          : _monthYearText.trim(),
      savingsAmount: double.tryParse(_savingsController.text) ?? 1000.0,
      interestPaid: double.tryParse(_interestPaidController.text) ?? 0.0,
      principalPaid: double.tryParse(_principalPaidController.text) ?? 0.0,
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;

    if (shareOnWhatsApp) {
      final text = WhatsAppService.buildPaymentReceiptText(
        group: group,
        member: member,
        payment: payment,
        totalMemberSavings: _storage.getTotalSavingsForMember(member.id),
      );
      await WhatsAppService.sendWhatsAppMessage(
          phoneNumber: member.phone, messageText: text);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(shareOnWhatsApp
              ? 'Payment saved and WhatsApp opened'
              : 'Payment saved successfully')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final group = _selectedGroupId == null
        ? (_storage.groups.isNotEmpty ? _storage.groups.first : null)
        : _storage.groups.firstWhere((g) => g.id == _selectedGroupId,
            orElse: () => _storage.groups.first);
    final members = group == null
        ? <BachatMember>[]
        : _storage.getMembersForGroup(group.id);

    return Scaffold(
      backgroundColor: Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Color(0xFF1B5E20),
        title: Text('Record Payment',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (group != null) ...[
                  Text('Bachat Gat',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey[700])),
                  SizedBox(height: 6),
                  Text(group.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20))),
                  SizedBox(height: 16),
                ],
                Text('Select Member',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey[700])),
                SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedMemberId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.person, color: Color(0xFF1B5E20)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  items: members.map((m) {
                    final activeLoan = _storage.getActiveLoanForMember(m.id);
                    final loanBadge = activeLoan != null
                        ? ' | Loan ${_currencyFormat.format(activeLoan.remainingPrincipal)}'
                        : '';
                    return DropdownMenuItem(
                        value: m.id,
                        child: Text('${m.name}$loanBadge',
                            overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedMemberId = val);
                    _updateLoanDetailsAndTotals();
                  },
                ),
                SizedBox(height: 16),
                _buildTextFieldLabel('Month / Year'),
                TextFormField(
                  initialValue: _monthYearText,
                  decoration: _inputDecoration(
                      Icons.calendar_today, 'e.g. August 2026'),
                  onChanged: (val) => _monthYearText = val,
                ),
                SizedBox(height: 16),
                _buildTextFieldLabel('Fixed Monthly Savings'),
                TextField(
                  controller: _savingsController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(Icons.savings, '1000'),
                ),
                SizedBox(height: 20),
                if (_hasActiveLoan) ...[
                  _buildLoanBox(),
                  SizedBox(height: 20),
                ],
                _buildTotalBox(),
                SizedBox(height: 16),
                _buildTextFieldLabel('Remarks / Notes'),
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Paid cash in meeting',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(Icons.save),
                        label: Text('Save',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _isSaving
                            ? null
                            : () => _savePayment(shareOnWhatsApp: false),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(Icons.message),
                        label: Text('Share WhatsApp',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _isSaving
                            ? null
                            : () => _savePayment(shareOnWhatsApp: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.grey[700])),
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Color(0xFF1B5E20)),
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _buildLoanBox() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: Colors.amber[900]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Active loan repayment',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[900],
                      fontSize: 13),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildAmountRow('Current Principal',
              _currencyFormat.format(_currentLoanPrincipal), Colors.red[900]!),
          _buildAmountRow(
              '2% Interest Due',
              _currencyFormat.format(_calculatedInterestDue),
              Colors.blue[900]!),
          SizedBox(height: 12),
          _buildTextFieldLabel('Interest Paid'),
          TextField(
            controller: _interestPaidController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(Icons.percent, '0'),
          ),
          SizedBox(height: 12),
          _buildTextFieldLabel('Principal Repayment'),
          TextField(
            controller: _principalPaidController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(Icons.price_change, 'e.g. 2000'),
          ),
          SizedBox(height: 12),
          _buildAmountRow(
              'New Remaining Principal',
              _currencyFormat.format(_remainingLoanPrincipalAfterPayment),
              Colors.green[900]!),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]))),
          SizedBox(width: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBox() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1B5E20).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xFF1B5E20).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOTAL AMOUNT SUBMITTED',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20))),
                SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _currencyFormat.format(_totalAmountSubmitted),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20)),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline, color: Color(0xFF1B5E20), size: 32),
        ],
      ),
    );
  }
}
