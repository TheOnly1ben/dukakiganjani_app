import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

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
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
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

class EmployeeLoginPage extends StatefulWidget {
  const EmployeeLoginPage({Key? key}) : super(key: key);

  @override
  State<EmployeeLoginPage> createState() => _EmployeeLoginPageState();
}

class _EmployeeLoginPageState extends State<EmployeeLoginPage> {
  final TextEditingController _employeeIdController = TextEditingController();
  final List<TextEditingController> _pinBoxControllers = List.generate(4, (index) => TextEditingController());
  bool _isLoading = false;

  @override
  void dispose() {
    _employeeIdController.dispose();
    for (var controller in _pinBoxControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getPin() {
    return _pinBoxControllers.map((controller) => controller.text).join();
  }

  Future<void> _handleLogin() async {
    final username = _employeeIdController.text.trim();
    final pin = _getPin();

    if (username.isEmpty || pin.length != 4) {
      debugPrint('❌ Employee login failed: Username or PIN is empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter both Username and PIN')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🔐 Attempting employee login for username: $username');

      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.loginEmployee(username, pin);

      if (success) {
        if (mounted) {
          // AuthService will handle navigation through AuthWrapper
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authService.lastError ?? 'Login failed'),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Employee login error: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF00C853),
            size: 28,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: 160,
                    height: 160,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.store,
                          size: 90,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  
                  // Employee ID Input
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _employeeIdController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'employee_login.id_label'.tr(),
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF00C853)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // PIN Label
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'employee_login.pin_label'.tr(),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF00C853),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Row(
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
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    width: 320,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoading ? Colors.grey : const Color(0xFF00C853),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
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
    );
  }
}
