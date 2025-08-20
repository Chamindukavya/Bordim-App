
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});

  
  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: _buildModernAppBar(context, colorScheme),
      body: Center(
        child: const Text('User Information'),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context, ColorScheme colorScheme) {
    return AppBar(
      elevation: 0,
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimaryContainer,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              color: colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Bordim Users',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Home',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
            HapticFeedback.selectionClick();
          },
          icon: const Icon(Icons.home_rounded),
        ),
      ],
    );
  }



}