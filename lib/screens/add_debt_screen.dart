import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _addDebt() async {
    final String email = _userEmailController.text.trim();
    final String amountText = _amountController.text.trim();
    if (email.isEmpty || amountText.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      return;
    }
    final double? amount = double.tryParse(amountText);
    if (amount == null) {
      setState(() => _error = 'Amount must be a number');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      final CollectionReference<Map<String, dynamic>> debts = FirebaseFirestore
          .instance
          .collection('users')
          .doc(uid)
          .collection('debts');

      await debts.add({
        'otherUserEmail': email,
        'amount': amount,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = 'Failed to add debt');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add debt'),
        actions: [
          IconButton(
            tooltip: 'Home',
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            icon: const Icon(Icons.home_outlined),
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _userEmailController,
                  decoration: const InputDecoration(
                    labelText: 'Other user email',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
                FilledButton.icon(
                  onPressed: _saving ? null : _addDebt,
                  icon: const Icon(Icons.save_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


