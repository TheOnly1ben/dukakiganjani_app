import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../model/store.dart';
import '../model/customer_credit.dart';
import '../services/supabase_service.dart';

class DebtsPage extends StatefulWidget {
  final Store store;

  const DebtsPage({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  bool _isLoading = true;
  List<CustomerCredit> _debts = [];
  Map<String, dynamic>? _debtSummary;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);

    try {
      final debts =
          await SupabaseService.getCustomerCreditsForStore(widget.store.id);
      final summary =
          await SupabaseService.getCustomerCreditSummary(widget.store.id);

      setState(() {
        _debts = debts;
        _debtSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load debts: $e')),
        );
      }
    }
  }

  void _showAddPaymentDialog(CustomerCredit debt) {
    showDialog(
      context: context,
      builder: (context) => AddPaymentDialog(debt: debt),
    ).then((result) {
      if (result == true) {
        _loadDebts();
      }
    });
  }

  void _showDebtDetails(CustomerCredit debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) =>
          DebtDetailsSheet(debt: debt, onPaymentAdded: _loadDebts),
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
          'debts.title'.tr(),
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Debt Summary
                if (_debtSummary != null) _buildDebtSummary(),

                // Debts List
                Expanded(
                  child: _debts.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _debts.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final debt = _debts[index];
                            return InkWell(
                              onTap: () => _showDebtDetails(debt),
                              child: _buildDebtCard(debt),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDebtSummary() {
    final totalDebts = _debtSummary!['total_credits'] as int? ?? 0;
    final totalOutstanding =
        _debtSummary!['total_outstanding'] as double? ?? 0.0;
    final totalPaid = _debtSummary!['total_paid'] as double? ?? 0.0;

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
                'debts.total_debts'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$totalDebts ${'debts.title'.tr().toLowerCase()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF00C853),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'debts.total_paid'.tr(),
                  '${totalPaid.toStringAsFixed(0)} TZS',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'debts.total_debts'.tr(),
                  '${totalOutstanding.toStringAsFixed(0)} TZS',
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
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
            Icons.credit_card_off,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'debts.no_debts'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Madeni yote yamelipwa!',
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

  Widget _buildDebtCard(CustomerCredit debt) {
    final progress =
        debt.totalCredit > 0 ? debt.paidAmount / debt.totalCredit : 0.0;
    final statusColor = debt.status == 'paid'
        ? Colors.green
        : debt.status == 'overdue'
            ? Colors.red
            : Colors.orange;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sale #${debt.saleId.substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'debts.${debt.status}'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${debt.paidAmount.toStringAsFixed(0)} / ${debt.totalCredit.toStringAsFixed(0)} TZS',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${debt.balance.toStringAsFixed(0)} TZS imebaki',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${debt.createdAt.day}/${debt.createdAt.month}/${debt.createdAt.year}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (debt.status != 'paid')
                ElevatedButton.icon(
                  onPressed: () => _showAddPaymentDialog(debt),
                  icon: const Icon(Icons.payment, size: 16),
                  label: Text('debts.add_payment'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Add Payment Dialog
class AddPaymentDialog extends StatefulWidget {
  final CustomerCredit debt;

  const AddPaymentDialog({Key? key, required this.debt}) : super(key: key);

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _selectedPaymentMethod = 'cash';

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
    // Set default amount to remaining balance
    _amountController.text = widget.debt.balance.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _paymentDate) {
      setState(() {
        _paymentDate = picked;
      });
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    try {
      await SupabaseService.updateCustomerCreditPayment(
        creditId: widget.debt.id!,
        paidAmount: amount,
      );

      Navigator.of(context).pop(true);

      if (amount >= widget.debt.balance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('debts.debt_paid_off'.tr())),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('debts.payment_successful'.tr())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imeshindwa kuongeza malipo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('debts.add_payment'.tr()),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Debt Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.debt.customerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Zilizobaki: ${widget.debt.balance.toStringAsFixed(0)} TZS',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'debts.payment_amount'.tr(),
                  suffixText: 'TZS',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'debts.amount_required'.tr();
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'debts.amount_invalid'.tr();
                  }
                  if (amount > widget.debt.balance) {
                    return 'debts.amount_too_large'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: InputDecoration(
                  labelText: 'debts.payment_method'.tr(),
                  border: const OutlineInputBorder(),
                ),
                items: _paymentMethods.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text('debts.${method.toLowerCase()}'.tr()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'debts.payment_date'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(
                    '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'debts.notes'.tr(),
                  hintText: 'Maelezo ya malipo (si lazima)',
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
          child: Text('debts.cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _savePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
          ),
          child: Text('debts.confirm_payment'.tr()),
        ),
      ],
    );
  }
}

// Debt Details Bottom Sheet
class DebtDetailsSheet extends StatelessWidget {
  final CustomerCredit debt;
  final VoidCallback onPaymentAdded;

  const DebtDetailsSheet({
    Key? key,
    required this.debt,
    required this.onPaymentAdded,
  }) : super(key: key);

  void _showAddPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddPaymentDialog(debt: debt),
    ).then((result) {
      if (result == true) {
        onPaymentAdded();
        Navigator.pop(context); // Close the details sheet
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        debt.totalCredit > 0 ? debt.paidAmount / debt.totalCredit : 0.0;
    final statusColor = debt.status == 'paid'
        ? Colors.green
        : debt.status == 'overdue'
            ? Colors.red
            : Colors.orange;

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
                'Maelezo ya Deni',
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

          // Debt Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildDetailRow('Mteja', debt.customerName),
                const SizedBox(height: 8),
                _buildDetailRow(
                    'Jumla', '${debt.totalCredit.toStringAsFixed(0)} TZS'),
                const SizedBox(height: 8),
                _buildDetailRow(
                    'Amelipa', '${debt.paidAmount.toStringAsFixed(0)} TZS'),
                const SizedBox(height: 8),
                _buildDetailRow(
                    'Imebaki', '${debt.balance.toStringAsFixed(0)} TZS'),
                const SizedBox(height: 8),
                _buildDetailRow('Hali', 'debts.${debt.status}'.tr()),
                const SizedBox(height: 8),
                _buildDetailRow('Tarehe ya Mauzo',
                    '${debt.createdAt.day}/${debt.createdAt.month}/${debt.createdAt.year}'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Maendeleo ya Malipo',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(1)}% imelipwa',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action Button
          if (debt.status != 'paid')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddPaymentDialog(context),
                icon: const Icon(Icons.payment),
                label: Text('debts.add_payment'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
