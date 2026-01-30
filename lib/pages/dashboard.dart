import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../model/store.dart';
import '../model/employees.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';
import 'inventory.dart';
import 'category.dart';
import 'sales.dart';
import 'reports.dart';
import 'employees.dart';
import 'expenses.dart';
import 'debts.dart';
import 'employee_sales.dart';

class OwnerDashboardPage extends StatelessWidget {
  final Store store;

  const OwnerDashboardPage({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              store.name,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${store.type}${store.location != null ? " • ${store.location}" : ""}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: store.status == 'Active'
                  ? const Color(0xFF00C853).withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: store.status == 'Active'
                        ? const Color(0xFF00C853)
                        : Colors.grey.shade500,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  store.status,
                  style: TextStyle(
                    color: store.status == 'Active'
                        ? const Color(0xFF00C853)
                        : Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Color(0xFF1A1A1A),
            ),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categories Chips
                _buildCategoriesChips(context),
                const SizedBox(height: 24),

                // Quick Actions Grid
                _buildQuickActions(context),
                const SizedBox(height: 32),

                // Store Stats
                _buildStoreStats(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'dashboard.quick_actions'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionButton(
              icon: Icons.inventory_2_outlined,
              label: 'dashboard.inventory'.tr(),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => InventoryPage(store: store),
                  ),
                );
              },
            ),
            _buildActionButton(
              icon: Icons.shopping_bag_outlined,
              label: 'dashboard.sales'.tr(),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SalesPage(store: store),
                  ),
                );
              },
            ),
            _buildActionButton(
              icon: Icons.people_outline,
              label: 'dashboard.staff'.tr(),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EmployeesPage(store: store),
                  ),
                );
              },
            ),
            _buildActionButton(
              icon: Icons.bar_chart_rounded,
              label: 'dashboard.reports'.tr(),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ReportsPage(store: store),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF00C853),
                  size: 28,
                ),
                const Spacer(),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesChips(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            ActionChip(
              avatar: const Icon(
                Icons.category,
                color: Color(0xFF00C853),
              ),
              label: Text(
                'categories.title'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CategoryPage(store: store),
                  ),
                );
              },
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ActionChip(
              avatar: const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF00C853),
              ),
              label: Text(
                'expenses.title'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ExpensesPage(store: store),
                  ),
                );
              },
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ActionChip(
              avatar: const Icon(
                Icons.credit_card,
                color: Color(0xFF00C853),
              ),
              label: Text(
                'debts.title'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DebtsPage(store: store),
                  ),
                );
              },
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStoreStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'dashboard.store_information'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildStatRow('dashboard.status'.tr(), store.status),
              _buildDivider(),
              _buildStatRow('dashboard.type'.tr(), store.type),
              _buildDivider(),
              _buildStatRow(
                  'dashboard.created'.tr(), _formatDate(store.createdAt)),
              if (store.currency != null) ...[
                _buildDivider(),
                _buildStatRow('dashboard.currency'.tr(), store.currency!),
              ],
              if (store.location != null) ...[
                _buildDivider(),
                _buildStatRow('dashboard.location'.tr(), store.location!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('dashboard.logout'.tr()),
        content: Text('dashboard.logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('dashboard.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Use AuthService to logout properly
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              // Clear navigation stack and go back to onboarding page
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('dashboard.logout'.tr()),
          ),
        ],
      ),
    );
  }
}

// Employee Dashboard Page - Limited functionality for employees
class EmployeeDashboardPage extends StatelessWidget {
  final Store store;
  final Employee employee;

  const EmployeeDashboardPage({
    Key? key,
    required this.store,
    required this.employee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              store.name,
              style: const TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'dashboard.welcome_back'.tr(args: [employee.fullName]),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.logout,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () => _showLogoutDialog(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00C853),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'dashboard.employee'.tr(),
                  style: const TextStyle(
                    color: Color(0xFF00C853),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Actions Grid for Employees
                _buildEmployeeQuickActions(context),
                const SizedBox(height: 32),

                // Employee Info Card
                _buildEmployeeInfoCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'dashboard.quick_actions'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildActionButton(
              icon: Icons.inventory_2_outlined,
              label: 'dashboard.view_inventory'.tr(),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => InventoryPage(store: store),
                  ),
                );
              },
            ),
            _buildActionButton(
              icon: Icons.shopping_bag_outlined,
              label: 'dashboard.make_sales'.tr(),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SalesPage(store: store),
                  ),
                );
              },
            ),
            _buildActionButton(
              icon: Icons.receipt_long,
              label: 'dashboard.my_sales'.tr(),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EmployeeSalesPage(
                      store: store,
                      employee: employee,
                    ),
                  ),
                );
              },
            ),
            _buildActionButton(
              icon: Icons.category,
              label: 'dashboard.browse_categories'.tr(),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CategoryPage(store: store),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF00C853),
                  size: 28,
                ),
                const Spacer(),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeInfoCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'dashboard.your_information'.tr(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildInfoRow('dashboard.name'.tr(), employee.fullName),
              _buildDivider(),
              _buildInfoRow('dashboard.username'.tr(), employee.username),
              _buildDivider(),
              _buildInfoRow('dashboard.role'.tr(), 'dashboard.employee'.tr()),
              if (employee.phone != null) ...[
                _buildDivider(),
                _buildInfoRow('dashboard.phone'.tr(), employee.phone!),
              ],
              _buildDivider(),
              _buildInfoRow(
                  'dashboard.status'.tr(),
                  employee.isActive
                      ? 'dashboard.active'.tr()
                      : 'dashboard.inactive'.tr()),
              const SizedBox(height: 16),
              Center(
                child: Builder(
                  builder: (context) => OutlinedButton.icon(
                    onPressed: () => _showChangePinDialog(context),
                    icon: const Icon(Icons.lock, size: 18),
                    label: Text('dashboard.change_pin'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00C853),
                      side: const BorderSide(color: Color(0xFF00C853)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showChangePinDialog(BuildContext context) {
    final TextEditingController currentPinController = TextEditingController();
    final TextEditingController newPinController = TextEditingController();
    final TextEditingController confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('dashboard.change_pin'.tr()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPinController,
                decoration: InputDecoration(
                  labelText: 'dashboard.current_pin'.tr(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'dashboard.enter_current_pin'.tr();
                  }
                  if (value.length != 4) {
                    return 'dashboard.pin_must_4_digits'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPinController,
                decoration: InputDecoration(
                  labelText: 'dashboard.new_pin'.tr(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'dashboard.enter_new_pin'.tr();
                  }
                  if (value.length != 4) {
                    return 'dashboard.pin_must_4_digits'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPinController,
                decoration: InputDecoration(
                  labelText: 'dashboard.confirm_new_pin'.tr(),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'dashboard.confirm_new_pin_req'.tr();
                  }
                  if (value != newPinController.text) {
                    return 'dashboard.pins_not_match'.tr();
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('dashboard.cancel'.tr()),
          ),
          Builder(
            builder: (dialogContext) => ElevatedButton(
              onPressed: () => _changePin(
                dialogContext,
                currentPinController.text,
                newPinController.text,
                confirmPinController.text,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
              ),
              child: Text('dashboard.change_pin'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePin(
    BuildContext context,
    String currentPin,
    String newPin,
    String confirmPin,
  ) async {
    // Validate inputs
    if (currentPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('dashboard.enter_current_pin'.tr())),
      );
      return;
    }

    if (newPin.length != 4 || confirmPin.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('dashboard.pin_must_4_digits'.tr())),
      );
      return;
    }

    if (newPin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('dashboard.pins_not_match'.tr())),
      );
      return;
    }

    if (currentPin == newPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('dashboard.pin_diff_from_current'.tr())),
      );
      return;
    }

    try {
      // Verify current PIN by attempting authentication
      final fakeEmail = '${employee.username}@dukakiganjani.com';
      final currentPassword = '$currentPin@dukakiganjani';

      final authResponse =
          await Supabase.instance.client.auth.signInWithPassword(
        email: fakeEmail,
        password: currentPassword,
      );

      if (authResponse.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('dashboard.enter_current_pin'.tr())),
        );
        return;
      }

      // Update password in Supabase Auth
      final newPassword = '$newPin@dukakiganjani';
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // Close dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('dashboard.pin_changed_success'.tr())),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('dashboard.change_pin'.tr() + ': ${e.toString()}')),
      );
    }
  }

  Widget _buildStoreInfoCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            'Store Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildInfoRow('Store Name', store.name),
              _buildDivider(),
              _buildInfoRow('Type', store.type),
              if (store.location != null) ...[
                _buildDivider(),
                _buildInfoRow('Location', store.location!),
              ],
              _buildDivider(),
              _buildInfoRow('Status', store.status),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('dashboard.logout'.tr()),
        content: Text('dashboard.logout_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('dashboard.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Use AuthService to logout properly
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              // Clear navigation stack and go back to onboarding page
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('dashboard.logout'.tr()),
          ),
        ],
      ),
    );
  }
}
