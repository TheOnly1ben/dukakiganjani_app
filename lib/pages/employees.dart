import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import '../model/store.dart';
import '../model/employees.dart';
import '../services/supabase_service.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return '';
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class EmployeesPage extends StatefulWidget {
  final Store store;

  const EmployeesPage({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  bool _isLoading = true;
  List<StoreEmployee> _storeEmployees = [];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('📋 Loading employees for store: ${widget.store.id}');
      final storeEmployees = await SupabaseService.getEmployeesForStore(widget.store.id);
      debugPrint('✅ Successfully loaded ${storeEmployees.length} employees');
      setState(() {
        _storeEmployees = storeEmployees;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to load employees: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('employees.load_failed'.tr())),
        );
      }
    }
  }

  void _showAddEmployeeDialog({StoreEmployee? employee}) {
    showDialog(
      context: context,
      builder: (context) => AddEmployeeDialog(
        store: widget.store,
        storeEmployee: employee,
      ),
    ).then((result) {
      if (result == true) {
        _loadEmployees();
      }
    });
  }

  void _showEmployeeDetails(StoreEmployee storeEmployee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => EmployeeDetailsSheet(
        storeEmployee: storeEmployee,
        onDelete: () {
          Navigator.pop(context);
          _loadEmployees();
        },
        onEdit: () {
          Navigator.pop(context);
          _showAddEmployeeDialog(employee: storeEmployee);
        },
        onStatusChange: () {
          Navigator.pop(context);
          _loadEmployees();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          'employees.title'.tr(),
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A), size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF00C853), size: 24),
            onPressed: () => _showAddEmployeeDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _storeEmployees.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Padding for bottom button
                  itemCount: _storeEmployees.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final storeEmployee = _storeEmployees[index];
                    return InkWell(
                      onTap: () => _showEmployeeDetails(storeEmployee),
                      child: _buildEmployeeCard(storeEmployee),
                    );
                  },
                ),
      bottomSheet: Container(
        color: const Color(0xFFFAFAFA),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showAddEmployeeDialog(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: Text(
            'Ongeza mfanyakazi',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'employees.no_employees'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'employees.add_first_employee'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(StoreEmployee storeEmployee) {
    final isActive = storeEmployee.employee?.isActive ?? true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isActive
                    ? const Color(0xFF00C853).withOpacity(0.1)
                    : Colors.grey.shade300,
                child: Text(
                  storeEmployee.displayName.isNotEmpty ? storeEmployee.displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFF00C853) : Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeEmployee.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'employees.role_label'.tr(args: [storeEmployee.role.value]),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleColor(storeEmployee.role).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      storeEmployee.role.value,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getRoleColor(storeEmployee.role),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'employees.active'.tr() : 'employees.inactive'.tr(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(EmployeeRole role) {
    switch (role) {
      case EmployeeRole.owner:
        return Colors.purple;
      case EmployeeRole.manager:
        return Colors.blue;
      case EmployeeRole.cashier:
        return Colors.green;
      case EmployeeRole.staff:
      default:
        return Colors.orange;
    }
  }
}

// Add/Edit Employee Dialog
class AddEmployeeDialog extends StatefulWidget {
  final StoreEmployee? storeEmployee;
  final Store? store;

  const AddEmployeeDialog({Key? key, this.storeEmployee, this.store}) : super(key: key);

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  EmployeeRole _selectedRole = EmployeeRole.staff;
  bool _isLoading = false;

  // Filtered list of roles excluding 'Owner'
  final List<EmployeeRole> _dropdownRoles =
      EmployeeRole.values.where((role) => role != EmployeeRole.owner).toList();

  @override
  void initState() {
    super.initState();

    if (widget.storeEmployee != null) {
      final currentRole = widget.storeEmployee!.role;
      // Ensure the selected role is valid, defaulting to staff if not
      _selectedRole = _dropdownRoles.contains(currentRole) ? currentRole : EmployeeRole.staff;
      _fullNameController.text = widget.storeEmployee!.displayName;
      _usernameController.text = widget.storeEmployee!.username ?? '';
      _phoneController.text = widget.storeEmployee!.phone ?? '';
    } else {
      _fullNameController.addListener(_generateUsername);
    }
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_generateUsername);
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _generateUsername() {
    final fullName = _fullNameController.text.trim();
    if (fullName.isNotEmpty) {
      final names = fullName.split(' ');
      final firstName = names[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      final randomCode = _generateRandomCode();
      _usernameController.text = '$firstName$randomCode';
    } else {
      _usernameController.clear();
    }
  }

  String _generateRandomCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(4, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.storeEmployee != null) {
        // Update existing store employee role
        await SupabaseService.updateStoreEmployee(
          storeEmployeeId: widget.storeEmployee!.id,
          role: _selectedRole,
        );
      } else {
        // Add new employee to store
        if (widget.store == null) throw Exception('Store information not available');

        final newEmployee = await SupabaseService.createEmployee(
          fullName: _fullNameController.text.trim(),
          username: _usernameController.text.trim(),
          phone: _phoneController.text.trim(),
          pin: _pinController.text.trim(),
        );

        await SupabaseService.addEmployeeToStore(
          storeId: widget.store!.id,
          employeeId: newEmployee.id,
          role: _selectedRole,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.storeEmployee != null ? 'employees.update_success'.tr() : 'employees.add_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to save employee: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('employees.save_failed'.tr()),
            backgroundColor: Colors.red,
          ),
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
    final isEditing = widget.storeEmployee != null;

    return AlertDialog(
      title: Text(isEditing ? 'employees.edit_role_title'.tr() : 'employees.add_employee_title'.tr()),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isEditing) ...[
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(labelText: 'employees.full_name_label'.tr()),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'employees.full_name_required'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: 'employees.username_label_form'.tr()),
                  readOnly: true,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'employees.phone_label'.tr()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pinController,
                  decoration: InputDecoration(labelText: 'employees.pin_label'.tr()),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'employees.pin_required'.tr();
                    }
                    if (value.length != 4) {
                      return 'employees.pin_length_error'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'employees.role'.tr(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              DropdownButtonFormField<EmployeeRole>(
                value: _selectedRole,
                items: _dropdownRoles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.value.capitalize()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('employees.cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveEmployee,
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('employees.save'.tr()),
        ),
      ],
    );
  }
}

class EmployeeDetailsSheet extends StatelessWidget {
  final StoreEmployee storeEmployee;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onStatusChange;

  const EmployeeDetailsSheet({
    Key? key,
    required this.storeEmployee,
    required this.onDelete,
    required this.onEdit,
    required this.onStatusChange,
  }) : super(key: key);

  Future<void> _toggleStatus(BuildContext context) async {
    final isActive = storeEmployee.employee?.isActive ?? false;
    try {
      if (isActive) {
        await SupabaseService.deactivateEmployee(storeEmployee.employeeId);
      } else {
        await SupabaseService.reactivateEmployee(storeEmployee.employeeId);
      }
      onStatusChange();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('employees.status_change_failed'.tr())),
        );
      }
    }
  }

  Future<void> _deleteEmployee(BuildContext context) async {
    try {
      await SupabaseService.removeEmployeeFromStore(storeEmployee.id);
      onDelete();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('employees.delete_failed'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = storeEmployee.employee?.isActive ?? false;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(storeEmployee.displayName, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(storeEmployee.role.value, style: Theme.of(context).textTheme.titleMedium),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.edit),
            title: Text('employees.edit_role_title'.tr()),
            onTap: onEdit,
          ),
          ListTile(
            leading: Icon(isActive ? Icons.toggle_off : Icons.toggle_on),
            title: Text(isActive ? 'employees.deactivate'.tr() : 'employees.activate'.tr()),
            onTap: () => _toggleStatus(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text('employees.remove_employee'.tr(), style: const TextStyle(color: Colors.red)),
            onTap: () => _deleteEmployee(context),
          ),
        ],
      ),
    );
  }
}
