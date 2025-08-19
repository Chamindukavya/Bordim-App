import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    final currency = NumberFormat.currency(symbol: 'Rs');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bordim'),
        actions: [
          IconButton(
            tooltip: 'Home',
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            icon: const Icon(Icons.home_outlined),
          ),
          IconButton(
            tooltip: 'Add debt',
            onPressed: () => Navigator.pushNamed(context, '/add-debt'),
            icon: const Icon(Icons.add_card_outlined),
          ),
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your debts',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('debts')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        final double total = docs.fold(0.0, (sum, d) {
                          final v = d.data()['amount'];
                          return sum + (v is num ? v.toDouble() : 0.0);
                        });
                        return Chip(
                          label: Text('Total: ${currency.format(total)}'),
                          avatar: const Icon(Icons.summarize_outlined),
                        );
                      },
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('debts')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(child: Text('No debts yet'));
                        }
                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data();
                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline_rounded),
                              ),
                              title: Text(data['otherUserEmail'] ?? ''),
                              subtitle: Text(
                                'Created: ${(data['createdAt'] as Timestamp?)?.toDate().toLocal().toString().split(".").first ?? '-'}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(currency.format(data['amount'] ?? 0)), // ✅ formatted
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Edit',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () async {
                                      final amountController =
                                          TextEditingController(
                                              text: (data['amount'] ?? '')
                                                  .toString());
                                      final emailController =
                                          TextEditingController(
                                              text: data['otherUserEmail'] ?? '');
                                      final result = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Edit debt'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextField(
                                                controller: emailController,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Other user email',
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              TextField(
                                                controller: amountController,
                                                keyboardType:
                                                    const TextInputType
                                                            .numberWithOptions(
                                                        decimal: true),
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'Amount',
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Save'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (result == true) {
                                        final double? newAmount =
                                            double.tryParse(
                                                amountController.text.trim());
                                        if (newAmount != null) {
                                          await doc.reference.update({
                                            'otherUserEmail':
                                                emailController.text.trim(),
                                            'amount': newAmount,
                                          });
                                        }
                                      }
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      final confirm =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete debt'),
                                          content: const Text(
                                              'Are you sure you want to delete this debt?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await doc.reference.delete();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-debt'),
        icon: const Icon(Icons.add),
        label: const Text('Add debt'),
      ),
    );
  }
}
