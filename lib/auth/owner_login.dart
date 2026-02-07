import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class OwnerLoginPage extends StatefulWidget {
  const OwnerLoginPage({Key? key}) : super(key: key);

  @override
  State<OwnerLoginPage> createState() => _OwnerLoginPageState();
}

class _OwnerLoginPageState extends State<OwnerLoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final List<FocusNode> _pinFocusNodes =
      List.generate(4, (index) => FocusNode());
  bool _isLoading = false;
  final List<TextEditingController> _pinBoxControllers =
      List.generate(4, (index) => TextEditingController());

  String _getPin() {
    return _pinBoxControllers.map((controller) => controller.text).join();
  }

  void _handleLogin() async {
    final phone = _phoneController.text.trim();
    final pin = _getPin();

    if (phone.isEmpty || pin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter valid phone and PIN'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.loginOwner(phone, pin);

      if (success) {
        if (mounted) {
          // AuthService will handle navigation through AuthWrapper
          // Just close this screen
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authService.lastError ?? 'Login failed'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Login error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
    for (var controller in _pinBoxControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 180,
                  height: 180,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.store,
                        size: 70,
                        color: Colors.white,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Title
                Text(
                  'owner_login.title'.tr(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                Text(
                  'owner_login.subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                // Phone Number Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'owner_login.phone_label'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Phone Number Input
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.flag,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '+255',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'owner_login.phone_hint'.tr(),
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Example Phone
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'owner_login.phone_example'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // PIN Label
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'owner_login.pin_label'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // PIN Input - 4 Boxes
                Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF00C853),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: _PinBox(
                              index: index,
                              controller: _pinBoxControllers[index],
                              onChanged: (value) {
                                if (value.isEmpty && index > 0) {
                                  FocusScope.of(context).previousFocus();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLoading
                          ? Colors.grey[400]
                          : const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'owner_login.login_button'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Register Link
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/owner_register');
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'owner_login.no_account'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      children: [
                        TextSpan(
                          text: ' ${'owner_login.register_here'.tr()}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF00C853),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Employee Login Link
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/employee_login');
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'owner_login.employee_login_text'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                      ),
                      children: [
                        TextSpan(
                          text: ' ${'owner_login.employee_login_link'.tr()}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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

class _PinBox extends StatefulWidget {
  final int index;
  final TextEditingController controller;
  final Function(String)? onChanged;

  const _PinBox({
    Key? key,
    required this.index,
    required this.controller,
    this.onChanged,
  }) : super(key: key);

  @override
  State<_PinBox> createState() => _PinBoxState();
}

class _PinBoxState extends State<_PinBox> {
  final TextEditingController _boxController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _boxController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF212121),
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              // Move to next box
              if (widget.index < 3) {
                FocusScope.of(context).nextFocus();
              } else {
                _focusNode.unfocus();
              }
              // Call parent callback if provided
              widget.onChanged?.call(value);
            } else if (value.isEmpty && widget.index > 0) {
              // Handle backspace - move to previous box
              FocusScope.of(context).previousFocus();
              widget.onChanged?.call(value);
            }
          },
        ),
      ),
    );
  }
}
