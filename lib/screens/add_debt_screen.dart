import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/debt_service.dart';  // adjust path

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> with TickerProviderStateMixin {
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final DebtService _debtService = DebtService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  AnimationController? _slideAnimationController;
  AnimationController? _scaleAnimationController;
  AnimationController? _loadingAnimationController;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _scaleAnimation;
  Animation<double>? _loadingAnimation;

  bool _saving = false;
  String? _error;
  bool _showSuccess = false;
  bool _animationsInitialized = false;
  
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startEntryAnimations();
    
    // Add listeners to controllers for real-time validation
    _userEmailController.addListener(_clearError);
    _amountController.addListener(_clearError);
  }

  void _setupAnimations() {
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController!,
      curve: Curves.easeOutBack,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController!,
      curve: Curves.elasticOut,
    ));

    _loadingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController!,
      curve: Curves.easeInOut,
    ));

    setState(() {
      _animationsInitialized = true;
    });
  }

  void _startEntryAnimations() {
    if (_slideAnimationController != null) {
      _slideAnimationController!.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && _scaleAnimationController != null) {
          _scaleAnimationController!.forward();
        }
      });
    }
  }

  void _clearError() {
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  @override
  void dispose() {
    _slideAnimationController?.dispose();
    _scaleAnimationController?.dispose();
    _loadingAnimationController?.dispose();
    _userEmailController.dispose();
    _amountController.dispose();
    _emailFocusNode.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addDebt() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    final String email = _userEmailController.text.trim();
    final String amountText = _amountController.text.trim();

    if (email.isEmpty || amountText.isEmpty) {
      setState(() => _error = 'Please fill all fields');
      HapticFeedback.lightImpact();
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Please enter a valid amount greater than 0');
      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    _loadingAnimationController?.repeat();
    HapticFeedback.mediumImpact();

    try {
      await _debtService.addDebt(
        otherUserEmail: email,
        amount: amount,
      );

      _loadingAnimationController?.stop();
      setState(() {
        _saving = false;
        _showSuccess = true;
      });

      HapticFeedback.heavyImpact();
      
      // Show success animation and then navigate back
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      _loadingAnimationController?.stop();
      setState(() {
        _error = 'Failed to add debt. Please try again.';
        _saving = false;
      });
      HapticFeedback.lightImpact();
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final double? amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_showSuccess) {
      return _buildSuccessScreen(colorScheme);
    }

    // Show loading indicator while animations are being initialized
    if (!_animationsInitialized) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('Add New Debt'),
          centerTitle: true,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildModernAppBar(context, colorScheme),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SlideTransition(
                position: _slideAnimation!,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderSection(context, colorScheme),
                    const SizedBox(height: 32),
                    _buildFormCard(context, colorScheme),
                    const SizedBox(height: 24),
                    ScaleTransition(
                      scale: _scaleAnimation!,
                      child: _buildActionButtons(context, colorScheme),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context, ColorScheme colorScheme) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
          HapticFeedback.lightImpact();
        },
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      title: Text(
        'Add New Debt',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeaderSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.add_card_rounded,
                  color: colorScheme.onPrimary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Debt Entry',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Record a new debt transaction',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Debt Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              _buildEmailField(colorScheme),
              const SizedBox(height: 20),
              _buildAmountField(colorScheme),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildErrorMessage(colorScheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField(ColorScheme colorScheme) {
    return TextFormField(
      controller: _userEmailController,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: _validateEmail,
      onFieldSubmitted: (_) {
        _amountFocusNode.requestFocus();
      },
      decoration: InputDecoration(
        labelText: 'Other User Email',
        hintText: 'Enter email address',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.email_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
    );
  }

  Widget _buildAmountField(ColorScheme colorScheme) {
    return TextFormField(
      controller: _amountController,
      focusNode: _amountFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      validator: _validateAmount,
      onFieldSubmitted: (_) {
        if (!_saving) _addDebt();
      },
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: 'Amount',
        hintText: 'Enter amount in Rs',
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.currency_rupee_rounded,
            color: colorScheme.onSecondaryContainer,
            size: 20,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
    );
  }

  Widget _buildErrorMessage(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_rounded,
            color: colorScheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: _saving ? null : _addDebt,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              disabledBackgroundColor: colorScheme.outline.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _saving
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Saving...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded),
                      SizedBox(width: 8),
                      Text(
                        'Save Debt',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: OutlinedButton(
            onPressed: _saving ? null : () {
              Navigator.pop(context);
              HapticFeedback.lightImpact();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              side: BorderSide(color: colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel_rounded),
                SizedBox(width: 8),
                Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen(ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 80,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Success!',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Debt has been added successfully',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}