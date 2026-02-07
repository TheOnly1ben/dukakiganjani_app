import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../model/store.dart';
import '../model/expenses.dart';
import '../services/offline_data_service.dart';
import '../services/supabase_service.dart';

class ExpensesPage extends StatefulWidget {
  final Store store;

  const ExpensesPage({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  bool _isLoading = true;
  List<Expense> _expenses = [];
  Map<String, dynamic>? _expenseSummary;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPaymentMethod;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);

    try {
      final expenses = await SupabaseService.getExpensesForStore(
        widget.store.id,
        startDate: _startDate,
        endDate: _endDate,
        paymentMethod: _selectedPaymentMethod,
      );

      final summary = await SupabaseService.getExpenseSummary(
        widget.store.id,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _expenses = expenses;
        _expenseSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load expenses: $e')),
        );
      }
    }
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(store: widget.store),
    ).then((result) {
      if (result == true) {
        _loadExpenses();
      }
    });
  }

  void _showExpenseDetails(Expense expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ExpenseDetailsSheet(
        expense: expense,
        onDelete: () {
          Navigator.pop(context);
          _loadExpenses();
        },
        onEdit: () {
          Navigator.pop(context);
          _showEditExpenseDialog(expense);
        },
      ),
    );
  }

  void _showEditExpenseDialog(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(expense: expense),
    ).then((result) {
      if (result == true) {
        _loadExpenses();
      }
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FilterExpensesSheet(
        startDate: _startDate,
        endDate: _endDate,
        selectedPaymentMethod: _selectedPaymentMethod,
        onApplyFilters: (startDate, endDate, paymentMethod) {
          setState(() {
            _startDate = startDate;
            _endDate = endDate;
            _selectedPaymentMethod = paymentMethod;
          });
          _loadExpenses();
        },
        onClearFilters: () {
          setState(() {
            _startDate = null;
            _endDate = null;
            _selectedPaymentMethod = null;
          });
          _loadExpenses();
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
          'expenses.title'.tr(),
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A), size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list,
                color: Color(0xFF1A1A1A), size: 22),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF00C853), size: 24),
            onPressed: _showAddExpenseDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Expense Summary
                if (_expenseSummary != null) _buildExpenseSummary(),

                // Expenses List
                Expanded(
                  child: _expenses.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _expenses.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final expense = _expenses[index];
                            return InkWell(
                              onTap: () => _showExpenseDetails(expense),
                              child: _buildExpenseCard(expense),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildExpenseSummary() {
    final totalExpenses = _expenseSummary!['total_expenses'] as int;
    final totalAmount = _expenseSummary!['total_amount'] as double;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'expenses.total_expenses'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$totalExpenses ${'expenses.title'.tr().toLowerCase()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF00C853),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${totalAmount.toStringAsFixed(0)} TZS',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFFDC3545),
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
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'expenses.no_expenses'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'expenses.add_first_expense'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddExpenseDialog,
            icon: const Icon(Icons.add),
            label: Text('expenses.add_expense'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final paymentMethod = expense.paymentMethod ?? 'other';
    final paymentMethodColor = _getPaymentMethodColor(paymentMethod);

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
              Expanded(
                child: Text(
                  expense.purpose,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: paymentMethodColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPaymentMethodText(paymentMethod),
                  style: TextStyle(
                    fontSize: 12,
                    color: paymentMethodColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (expense.notes != null && expense.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              expense.notes!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                '${expense.amount.toStringAsFixed(0)} TZS',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC3545),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'mpesa':
        return Colors.green;
      case 'tigo_pesa':
        return Colors.blue;
      case 'bank':
        return Colors.purple;
      case 'cheque':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentMethodText(String method) {
    return 'expenses.${method.toLowerCase()}'.tr();
  }
}

// Add/Edit Expense Dialog
class AddExpenseDialog extends StatefulWidget {
  final Expense? expense;
  final Store? store;

  const AddExpenseDialog({Key? key, this.expense, this.store})
      : super(key: key);

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _expenseDate = DateTime.now();
  String? _selectedPaymentMethod;

  final List<String> _paymentMethods = [
    'cash',
    'mpesa',
    'tigo_pesa',
    'bank',
    'cheque',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _purposeController.text = widget.expense!.purpose;
      _amountController.text = widget.expense!.amount.toString();
      _notesController.text = widget.expense!.notes ?? '';
      _expenseDate = widget.expense!.expenseDate;
      _selectedPaymentMethod = widget.expense!.paymentMethod;
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _expenseDate) {
      setState(() {
        _expenseDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final purpose = _purposeController.text.trim();
    final amount = double.parse(_amountController.text);
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    try {
      if (widget.expense != null) {
        // Update existing expense
        await OfflineDataService.updateExpenseWithParams(
          expenseId: widget.expense!.id!,
          purpose: purpose,
          amount: amount,
          paymentMethod: _selectedPaymentMethod,
          notes: notes,
          expenseDate: _expenseDate,
        );
      } else {
        // Add new expense
        if (widget.store == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Store information not available')),
          );
          return;
        }

        await OfflineDataService.addExpenseWithParams(
          storeId: widget.store!.id,
          purpose: purpose,
          amount: amount,
          paymentMethod: _selectedPaymentMethod,
          notes: notes,
          expenseDate: _expenseDate,
        );
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save expense: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.expense != null
            ? 'expenses.edit_expense'.tr()
            : 'expenses.add_expense'.tr(),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _purposeController,
                decoration: InputDecoration(
                  labelText: 'expenses.purpose'.tr(),
                  hintText: 'expenses.purpose_placeholder'.tr(),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'expenses.purpose_required'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'expenses.amount'.tr(),
                  suffixText: 'TZS',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'expenses.amount_required'.tr();
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'expenses.amount_invalid'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: InputDecoration(
                  labelText: 'expenses.payment_method'.tr(),
                  border: const OutlineInputBorder(),
                ),
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text('expenses.${method.toLowerCase()}'.tr()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'expenses.expense_date'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(
                    '${_expenseDate.day}/${_expenseDate.month}/${_expenseDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'expenses.notes'.tr(),
                  hintText: 'expenses.notes_placeholder'.tr(),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('expenses.cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _saveExpense,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
          ),
          child: Text('expenses.save'.tr()),
        ),
      ],
    );
  }
}

// Expense Details Bottom Sheet
class ExpenseDetailsSheet extends StatelessWidget {
  final Expense expense;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const ExpenseDetailsSheet({
    Key? key,
    required this.expense,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  Future<void> _deleteExpense(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('expenses.delete_expense'.tr()),
        content: Text('expenses.confirm_delete'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('expenses.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await OfflineDataService.deleteExpense(int.parse(expense.id!));
        onDelete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete expense: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Expense Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Expense Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildDetailRow('Purpose', expense.purpose),
                const SizedBox(height: 12),
                _buildDetailRow(
                    'Amount', '${expense.amount.toStringAsFixed(0)} TZS'),
                const SizedBox(height: 12),
                _buildDetailRow(
                    'Payment Method', expense.paymentMethod ?? 'Other'),
                const SizedBox(height: 12),
                _buildDetailRow('Date',
                    '${expense.expenseDate.day}/${expense.expenseDate.month}/${expense.expenseDate.year}'),
                if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('Notes', expense.notes!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00C853),
                    side: const BorderSide(color: Color(0xFF00C853)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _deleteExpense(context),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// Filter Expenses Bottom Sheet
class FilterExpensesSheet extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedPaymentMethod;
  final Function(DateTime?, DateTime?, String?) onApplyFilters;
  final VoidCallback onClearFilters;

  const FilterExpensesSheet({
    Key? key,
    this.startDate,
    this.endDate,
    this.selectedPaymentMethod,
    required this.onApplyFilters,
    required this.onClearFilters,
  }) : super(key: key);

  @override
  State<FilterExpensesSheet> createState() => _FilterExpensesSheetState();
}

class _FilterExpensesSheetState extends State<FilterExpensesSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedPaymentMethod;

  final List<String> _paymentMethods = [
    'cash',
    'mpesa',
    'tigo_pesa',
    'bank',
    'cheque',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
    _selectedPaymentMethod = widget.selectedPaymentMethod;
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chuja Matumizi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Date Range
          const Text(
            'Kipindi cha Tarehe',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, color: Color(0xFF00C853)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _startDate != null && _endDate != null
                          ? '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}'
                          : 'Chagua kipindi cha tarehe',
                      style: TextStyle(
                        color: _startDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Payment Method
          const Text(
            'Njia ya Malipo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Njia zote za malipo'),
              ),
              ..._paymentMethods.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text('expenses.${method.toLowerCase()}'.tr()),
                );
              }),
            ],
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onClearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Futa Chujio'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApplyFilters(
                        _startDate, _endDate, _selectedPaymentMethod);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                  ),
                  child: const Text('Tekeleza Chujio'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
