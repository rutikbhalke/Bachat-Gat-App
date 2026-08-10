import 'package:flutter/material.dart';
import '../model/bachat_models.dart';
import '../utils/bachat_storage_service.dart';

class BachatSettingsScreen extends StatefulWidget {
  const BachatSettingsScreen({Key? key}) : super(key: key);

  @override
  _BachatSettingsScreenState createState() => _BachatSettingsScreenState();
}

class _BachatSettingsScreenState extends State<BachatSettingsScreen> {
  final BachatStorageService _storage = BachatStorageService();
  final _nameController = TextEditingController();
  final _contributionController = TextEditingController();
  final _interestController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isReady = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contributionController.dispose();
    _interestController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    await _storage.init();
    final group = _storage.groups.isNotEmpty ? _storage.groups.first : null;
    if (group != null) {
      _applyGroup(group);
    }
    if (mounted) {
      setState(() => _isReady = true);
    }
  }

  void _applyGroup(BachatGroup group) {
    _nameController.text = group.name;
    _contributionController.text = group.monthlyContribution.toStringAsFixed(0);
    _interestController.text = group.interestRateMonthly.toString();
    _notesController.text = group.notes;
  }

  Future<void> _saveSettings() async {
    final name = _nameController.text.trim();
    final contribution = double.tryParse(_contributionController.text.trim());
    final interest = double.tryParse(_interestController.text.trim());

    if (name.isEmpty ||
        contribution == null ||
        contribution <= 0 ||
        interest == null ||
        interest < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid group settings')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await _storage.updateSingleGroup(
      name: name,
      monthlyContribution: contribution,
      interestRateMonthly: interest,
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved successfully')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Color(0xFF1B5E20),
        title: Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: !_isReady
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.groups, color: Color(0xFF1B5E20)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bachat Gat Details',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800]),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 18),
                          _buildLabel('Group Name'),
                          TextField(
                            controller: _nameController,
                            decoration: _inputDecoration(
                                Icons.edit, 'e.g. Jai Hanuman Bachat Gat'),
                          ),
                          SizedBox(height: 14),
                          _buildLabel('Monthly Contribution'),
                          TextField(
                            controller: _contributionController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(Icons.savings, '1000'),
                          ),
                          SizedBox(height: 14),
                          _buildLabel('Monthly Loan Interest (%)'),
                          TextField(
                            controller: _interestController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(Icons.percent, '2.0'),
                          ),
                          SizedBox(height: 14),
                          _buildLabel('Notes'),
                          TextField(
                            controller: _notesController,
                            minLines: 2,
                            maxLines: 4,
                            decoration:
                                _inputDecoration(Icons.notes, 'Optional notes'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 18),
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
                      icon: Icon(Icons.save),
                      label: Text('Save Settings',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _isSaving ? null : _saveSettings,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
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
      filled: true,
      fillColor: Colors.white,
    );
  }
}
