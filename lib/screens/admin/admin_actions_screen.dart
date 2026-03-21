import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';

class AdminActionsScreen extends ConsumerStatefulWidget {
  const AdminActionsScreen({super.key});

  @override
  ConsumerState<AdminActionsScreen> createState() => _AdminActionsScreenState();
}

class _AdminActionsScreenState extends ConsumerState<AdminActionsScreen> {
  int _activeTabIndex = 0; // 0: Deposit, 1: Transfer
  final _formKey = GlobalKey<FormState>();

  String _accountNumber = '';
  String _fromAccount = '';
  String _toAccount = '';
  String _amount = '';
  String _description = '';
  bool _isLoading = false;

  Future<void> _handleAction() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final apiService = ref.read(apiServiceProvider);

      if (_activeTabIndex == 0) {
        await apiService.adminDeposit(
          _accountNumber,
          double.parse(_amount),
          _description,
        );
      } else {
        await apiService.adminTransfer(
          _fromAccount,
          _toAccount,
          double.parse(_amount),
          _description,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_activeTabIndex == 0 ? 'Deposit' : 'Transfer'} successful!'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState!.reset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank Operations')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTabIndex == 0 ? Theme.of(context).primaryColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Deposit Funds',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _activeTabIndex == 0 ? Theme.of(context).primaryColor : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTabIndex == 1 ? Theme.of(context).primaryColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Inter-Account Transfer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _activeTabIndex == 1 ? Theme.of(context).primaryColor : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_activeTabIndex == 0)
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Customer Account Number',
                        hintText: 'BK1234567890',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      validator: (values) => values!.isEmpty ? 'Enter account number' : null,
                      onSaved: (value) => _accountNumber = value!,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'From Account',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            validator: (values) => values!.isEmpty ? 'Required' : null,
                            onSaved: (value) => _fromAccount = value!,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'To Account',
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            validator: (values) => values!.isEmpty ? 'Required' : null,
                            onSaved: (value) => _toAccount = value!,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Amount (RWF)',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (values) => values!.isEmpty ? 'Enter amount' : null,
                          onSaved: (value) => _amount = value!,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Optional note',
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          onSaved: (value) => _description = value ?? '',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Execute ${_activeTabIndex == 0 ? 'Deposit' : 'Transfer'}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
