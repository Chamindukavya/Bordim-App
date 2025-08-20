import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<Offset> _headerSlideAnimation;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
    
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutBack,
    ));
    
    _fabAnimationController.forward();
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final currency = NumberFormat.currency(symbol: 'Rs');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildModernAppBar(context, colorScheme),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SlideTransition(
                  position: _headerSlideAnimation,
                  child: _buildHeaderSection(context, uid, currency, colorScheme),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildDebtsSection(context, uid, currency, colorScheme),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: _buildInteractiveFAB(context, colorScheme),
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
            'Bordim',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Toggle view',
          onPressed: () {
            setState(() {
              _isGridView = !_isGridView;
            });
            HapticFeedback.lightImpact();
          },
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
              key: ValueKey(_isGridView),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Home',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/user-screen');
            HapticFeedback.selectionClick();
          },
          icon: const Icon(Icons.supervised_user_circle_sharp),
        ),
        IconButton(
          tooltip: 'Add debt',
          onPressed: () {
            Navigator.pushNamed(context, '/add-debt');
            HapticFeedback.selectionClick();
          },
          icon: const Icon(Icons.add_card_rounded),
        ),
        PopupMenuButton<String>(
          tooltip: 'More options',
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) {
            if (value == 'signout') {
              _showSignOutDialog(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'signout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded),
                  SizedBox(width: 12),
                  Text('Sign out'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderSection(BuildContext context, String uid, NumberFormat currency, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Debts',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
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
            
            return Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Total Amount',
                    currency.format(total),
                    Icons.account_balance_wallet_rounded,
                    colorScheme.primary,
                    colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Total Debts',
                    '${docs.length}',
                    Icons.receipt_long_rounded,
                    colorScheme.secondary,
                    colorScheme.onSecondary,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: textColor.withOpacity(0.8), size: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up_rounded, color: textColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtsSection(BuildContext context, String uid, NumberFormat currency, ColorScheme colorScheme) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('debts')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _buildEmptyState(colorScheme);
        }
        
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isGridView 
            ? _buildGridView(docs, currency, colorScheme)
            : _buildListView(docs, currency, colorScheme),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your debts...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No debts yet!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add your first debt',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, NumberFormat currency, ColorScheme colorScheme) {
    return ListView.separated(
      key: const ValueKey('list_view'),
      itemCount: docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data();
        return _buildDebtCard(doc, data, currency, colorScheme, false);
      },
    );
  }

  Widget _buildGridView(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, NumberFormat currency, ColorScheme colorScheme) {
    return GridView.builder(
      key: const ValueKey('grid_view'),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data();
        return _buildDebtCard(doc, data, currency, colorScheme, true);
      },
    );
  }

  Widget _buildDebtCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, dynamic> data,
    NumberFormat currency,
    ColorScheme colorScheme,
    bool isGridCard,
  ) {
    final amount = data['amount'] ?? 0;
    final email = data['otherUserEmail'] ?? '';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    
    return Hero(
      tag: doc.id,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showDebtDetails(context, doc, data, currency),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: isGridCard ? _buildGridCardContent(data, currency, colorScheme, doc, createdAt) 
                                  : _buildListCardContent(data, currency, colorScheme, doc, createdAt),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListCardContent(
    Map<String, dynamic> data,
    NumberFormat currency,
    ColorScheme colorScheme,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    DateTime? createdAt,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.person_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['otherUserEmail'] ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                createdAt != null
                    ? 'Created: ${DateFormat.yMMMd().format(createdAt)}'
                    : 'Created: -',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currency.format(data['amount'] ?? 0),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Edit',
              icon: Icon(Icons.edit_rounded, color: colorScheme.primary),
              onPressed: () => _showEditDialog(context, doc, data),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_rounded, color: colorScheme.error),
              onPressed: () => _showDeleteDialog(context, doc),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridCardContent(
    Map<String, dynamic> data,
    NumberFormat currency,
    ColorScheme colorScheme,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    DateTime? createdAt,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person_rounded,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, size: 20, color: colorScheme.onSurface.withOpacity(0.6)),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(context, doc, data);
                } else if (value == 'delete') {
                  _showDeleteDialog(context, doc);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [Icon(Icons.edit_rounded), SizedBox(width: 8), Text('Edit')],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [Icon(Icons.delete_rounded), SizedBox(width: 8), Text('Delete')],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          data['otherUserEmail'] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSecondaryContainer.withOpacity(0.7),
                ),
              ),
              Text(
                currency.format(data['amount'] ?? 0),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          createdAt != null
              ? DateFormat.yMMMd().format(createdAt)
              : 'No date',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveFAB(BuildContext context, ColorScheme colorScheme) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.pushNamed(context, '/add-debt');
        HapticFeedback.heavyImpact();
      },
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add Debt'),
      elevation: 8,
      heroTag: "add_debt_fab",
    );
  }

  void _showDebtDetails(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc, Map<String, dynamic> data, NumberFormat currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Debt Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Email', data['otherUserEmail'] ?? ''),
            _buildDetailRow('Amount', currency.format(data['amount'] ?? 0)),
            _buildDetailRow(
              'Created',
              (data['createdAt'] as Timestamp?)?.toDate().toLocal().toString().split(".").first ?? '-',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditDialog(context, doc, data);
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteDialog(context, doc);
                    },
                    icon: const Icon(Icons.delete_rounded),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc, Map<String, dynamic> data) async {
    final amountController = TextEditingController(text: (data['amount'] ?? '').toString());
    final emailController = TextEditingController(text: data['otherUserEmail'] ?? '');
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_rounded),
            SizedBox(width: 12),
            Text('Edit Debt'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'Other user email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.currency_rupee_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      final double? newAmount = double.tryParse(amountController.text.trim());
      if (newAmount != null) {
        await doc.reference.update({
          'otherUserEmail': emailController.text.trim(),
          'amount': newAmount,
        });
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange),
            SizedBox(width: 12),
            Text('Delete Debt'),
          ],
        ),
        content: const Text('Are you sure you want to delete this debt? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await doc.reference.delete();
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded),
            SizedBox(width: 12),
            Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      HapticFeedback.lightImpact();
    }
  }
}