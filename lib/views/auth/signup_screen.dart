// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_flow_app/state/division_state.dart';
import '../../state/auth_state.dart';
import '../widgets/responsive_card.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();
  final divisionController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Fetch divisions
    Future.microtask(() {
      ref.read(divisionListProvider.notifier).fetchDivisions();
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmPassController.dispose();
    divisionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _showDivisionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DivisionBottomSheet(
            onDivisionSelected: (division) {
              setState(() {
                divisionController.text = division;
              });
            },
            currentDivision: divisionController.text,
          ),
    );
  }

  void _submit() async {
    // Close keyboard
    FocusScope.of(context).unfocus();

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please agree to the Terms and Conditions'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    try {
      await ref
          .read(authStateProvider.notifier)
          .signup(
            usernameController.text.trim(),
            emailController.text.trim(),
            passController.text.trim(),
            confirmPassController.text.trim(),
            divisionController.text.trim().toUpperCase(),
          );

      final user = ref.read(authStateProvider).value;
      final error = ref.read(authStateProvider);

      if (user != null) {
        // Show success toast
        _showSuccessToast(context);

        // Navigate after toast animation completes
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (user.role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            Navigator.pushReplacementNamed(context, '/user');
          }
        });
      } else if (error.hasError) {
        _showErrorDialog(context, error.error.toString());
      }
    } catch (e) {
      _showErrorDialog(context, e.toString());
    }
  }

  void _showSuccessToast(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).size.height * 0.1,
            width: MediaQuery.of(context).size.width,
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Account Created!",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Welcome to TaskFlow",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);

    // Remove the toast after some time
    Future.delayed(const Duration(milliseconds: 2000), () {
      overlayEntry.remove();
    });
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 10),
                const Text("Signup Failed"),
              ],
            ),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF5E5),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              child: ResponsiveCard(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed:
                                  () => Navigator.pushReplacementNamed(
                                    context,
                                    '/auth',
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Image
                        Center(
                          child: Container(
                            width: size.width * 0.4,
                            height: size.width * 0.4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              'assets/images/LoginPageimg.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Heading
                        const Center(
                          child: Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            "Sign up to get started",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Username Field
                        _buildInputLabel("Username"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: usernameController,
                          textInputAction: TextInputAction.next,
                          validator: _validateUsername,
                          decoration: _inputDecoration(
                            hintText: "Choose a username",
                            prefixIcon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email Field
                        _buildInputLabel("Email Address"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: _validateEmail,
                          decoration: _inputDecoration(
                            hintText: "Enter your email",
                            prefixIcon: Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Division Field - Updated to show bottom sheet
                        _buildInputLabel("Division"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: divisionController,
                          readOnly: true,
                          onTap: _showDivisionBottomSheet,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Division is required';
                            }
                            return null;
                          },
                          decoration: _inputDecoration(
                            hintText: "Select division",
                            prefixIcon: Icons.business_outlined,
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        _buildInputLabel("Password"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: passController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          validator: _validatePassword,
                          decoration: _inputDecoration(
                            hintText: "Create a password",
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey.shade600,
                              ),
                              onPressed:
                                  () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password Field
                        _buildInputLabel("Confirm Password"),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: confirmPassController,
                          obscureText: _obscureConfirmPassword,
                          validator: _validateConfirmPassword,
                          decoration: _inputDecoration(
                            hintText: "Confirm your password",
                            prefixIcon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey.shade600,
                              ),
                              onPressed:
                                  () => setState(
                                    () =>
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Terms and Conditions
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _agreedToTerms,
                                onChanged:
                                    (value) =>
                                        setState(() => _agreedToTerms = value!),
                                activeColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                  children: const [
                                    TextSpan(text: "I agree to the "),
                                    TextSpan(
                                      text: "Terms of Service",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    TextSpan(text: " and "),
                                    TextSpan(
                                      text: "Privacy Policy",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Signup Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            onPressed: authState.isLoading ? null : _submit,
                            child:
                                authState.isLoading
                                    ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text(
                                      "Create Account",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Redirect
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account?",
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            TextButton(
                              onPressed:
                                  () => Navigator.pushReplacementNamed(
                                    context,
                                    '/login',
                                  ),
                              child: const Text(
                                "Log In",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Copyright
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "© TaskFlow. All rights reserved.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
    );
  }
}

// Division Bottom Sheet Widget
class DivisionBottomSheet extends ConsumerStatefulWidget {
  final Function(String) onDivisionSelected;
  final String currentDivision;

  const DivisionBottomSheet({
    super.key,
    required this.onDivisionSelected,
    required this.currentDivision,
  });

  @override
  ConsumerState<DivisionBottomSheet> createState() =>
      _DivisionBottomSheetState();
}

class _DivisionBottomSheetState extends ConsumerState<DivisionBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final divisions = ref.watch(divisionListProvider);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    // Filter divisions based on search query
    final filteredDivisions =
        divisions
            .where(
              (division) =>
                  division.toLowerCase().contains(_searchQuery.toLowerCase()),
            )
            .toList();

    return Container(
      height: size.height * (isTablet ? 0.6 : 0.75),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Select Division',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),

          // Search bar and Add button row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search divisions...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _addNewDivision(),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(isTablet ? 'Add Division' : 'Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Divisions list
          Expanded(
            child:
                filteredDivisions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredDivisions.length,
                      itemBuilder: (context, index) {
                        final division = filteredDivisions[index];
                        final isSelected = division == widget.currentDivision;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              division,
                              style: TextStyle(
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            trailing:
                                isSelected
                                    ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                    : const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                    ),
                            onTap: () {
                              widget.onDivisionSelected(division);
                              Navigator.pop(context);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tileColor:
                                isSelected
                                    ? Colors.green.shade50
                                    : Colors.grey.shade50,
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No divisions available'
                : 'No divisions found for "$_searchQuery"',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isNotEmpty)
            Text(
              'Tap "Add" to create this division',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }

  void _addNewDivision() async {
    final newDivision = _searchController.text.trim().toUpperCase();

    if (newDivision.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a division name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await ref.read(divisionListProvider.notifier).addDivision(newDivision);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Division "$newDivision" added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Select the newly added division
      widget.onDivisionSelected(newDivision);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add division: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
