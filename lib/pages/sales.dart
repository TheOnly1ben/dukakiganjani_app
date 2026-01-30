import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import '../model/store.dart';
import '../model/product.dart';
import '../model/sales.dart';
import '../services/supabase_service.dart';

class SalesPage extends StatefulWidget {
  final Store store;

  const SalesPage({Key? key, required this.store}) : super(key: key);

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  bool _isLoading = true;
  bool _isProcessing = false;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final List<CartItem> _cartItems = [];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();

  PaymentMethod _paymentMethod = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  Future<void> _loadProducts() async {
    try {
      final products = await SupabaseService.getProductsForStore(widget.store.id);
      if (mounted) {
        setState(() {
          _products = products;
          _filteredProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _addToCart(Product product) {
    setState(() {
      final maxStock = product.quantity ?? 0;
      if (maxStock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bidhaa \'${product.name}\' imekwisha.')),
        );
        return;
      }

      final existingIndex = _cartItems.indexWhere((item) => item.productId == product.id);

      if (existingIndex != -1) {
        final item = _cartItems[existingIndex];
        if (item.quantity < maxStock) {
          item.quantity++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Umefikia kiwango cha juu cha bidhaa zilizopo.')),
          );
        }
      } else {
        _cartItems.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      _cartItems.removeWhere((item) => item.productId == productId);
    });
  }

  void _updateQuantity(String productId, int newQuantity) {
    setState(() {
      final itemIndex = _cartItems.indexWhere((item) => item.productId == productId);
      if (itemIndex == -1) return;

      final item = _cartItems[itemIndex];
      final maxStock = item.product.quantity ?? 0;

      if (newQuantity <= 0) {
        _cartItems.removeAt(itemIndex);
      } else if (newQuantity > maxStock) {
        item.quantity = maxStock.toInt();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kiasi kimezidi, zimebaki ${maxStock.toInt()} pekee.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        item.quantity = newQuantity;
      }
    });
  }

  double get _total => _cartItems.fold(0, (sum, item) => sum + item.subtotal);

  void _processSale() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sales.cart_empty'.tr())),
      );
      return;
    }

    if (_paymentMethod == PaymentMethod.credit &&
        (_customerNameController.text.isEmpty || _customerPhoneController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('sales.customer_required'.tr())),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final customerName = _paymentMethod == PaymentMethod.credit ? _customerNameController.text : null;
      final customerPhone = _paymentMethod == PaymentMethod.credit ? _customerPhoneController.text : null;

      await SupabaseService.createSale(
        storeId: widget.store.id,
        cartItems: _cartItems,
        paymentMethod: _paymentMethod,
        customerName: customerName,
        customerPhone: customerPhone,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('sales.sale_success'.tr(args: [_total.toStringAsFixed(0)]))),
        );
      }

      setState(() {
        _cartItems.clear();
        _customerNameController.clear();
        _customerPhoneController.clear();
      });

      // Reload products to get updated stock
      _loadProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process sale: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showProductSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductSelectionSheet(
        products: _products,
        searchController: _searchController,
        filteredProducts: _filteredProducts,
        onProductSelected: (product) {
          _addToCart(product);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showQuantityDialog(CartItem item) {
    final quantityController = TextEditingController(text: item.quantity.toString());
    final maxStock = item.product.quantity?.toInt() ?? 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Badilisha Kiasi'),
          content: TextField(
            controller: quantityController,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Kiasi (Zipo: $maxStock)',
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              final newQuantity = int.tryParse(quantityController.text) ?? 0;
              _updateQuantity(item.productId, newQuantity);
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Ghairi'),
            ),
            TextButton(
              onPressed: () {
                final newQuantity = int.tryParse(quantityController.text) ?? 0;
                _updateQuantity(item.productId, newQuantity);
                Navigator.pop(context);
              },
              child: Text('Thibitisha'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
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
          'dashboard.sales'.tr(),
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
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853),
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: _showProductSelectionSheet,
              child: Text(
                'chagua bidhaa',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: _cartItems.isEmpty
                        ? _buildEmptyCart()
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _cartItems.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = _cartItems[index];
                              return _buildCartItemCard(item);
                            },
                          ),
                  ),
                  _buildBottomSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'sales.cart_empty_message'.tr(),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'sales.tap_to_add'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    final maxStock = item.product.quantity ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.price.toStringAsFixed(0)} TZS',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${item.subtotal.toStringAsFixed(0)} TZS',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _updateQuantity(item.productId, item.quantity - 1),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.remove,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _showQuantityDialog(item),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 32),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _updateQuantity(item.productId, item.quantity + 1),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: item.quantity < maxStock ? const Color(0xFF1A1A1A) : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _removeFromCart(item.productId),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentMethodButton(PaymentMethod.cash),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPaymentMethodButton(PaymentMethod.credit),
                  ),
                ],
              ),
              if (_paymentMethod == PaymentMethod.credit) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customerNameController,
                  decoration: InputDecoration(
                    labelText: 'sales.customer_name'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _customerPhoneController,
                  decoration: InputDecoration(
                    labelText: 'sales.customer_phone'.tr(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'sales.total'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${_total.toStringAsFixed(0)} TZS',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00C853),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'sales.process_sale'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodButton(PaymentMethod method) {
    final isSelected = _paymentMethod == method;
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _paymentMethod = method;
        });
      },
      icon: Icon(
        isSelected
            ? Icons.check_circle
            : (method == PaymentMethod.cash ? Icons.money : Icons.credit_card),
        color: isSelected ? Colors.white : const Color(0xFF00C853),
        size: 20,
      ),
      label: Text(
        method == PaymentMethod.cash ? 'sales.cash'.tr() : 'sales.credit'.tr(),
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF00C853) : Colors.white,
        side: BorderSide(color: isSelected ? const Color(0xFF00C853) : Colors.grey.shade300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _ProductSelectionSheet extends StatefulWidget {
  final List<Product> products;
  final TextEditingController searchController;
  final List<Product> filteredProducts;
  final ValueChanged<Product> onProductSelected;

  const _ProductSelectionSheet({
    required this.products,
    required this.searchController,
    required this.filteredProducts,
    required this.onProductSelected,
  });

  @override
  State<_ProductSelectionSheet> createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<_ProductSelectionSheet> {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: widget.searchController,
                  decoration: InputDecoration(
                    hintText: 'sales.search_products'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: widget.filteredProducts.isEmpty
                    ? Center(
                        child: Text('sales.no_products_found'.tr()),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: widget.filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = widget.filteredProducts[index];
                          return ListTile(
                            title: Text(product.name),
                            subtitle: Text('${product.sellingPrice.toStringAsFixed(0)} TZS'),
                            trailing: Text('sales.stock_label'.tr(args: [product.quantity.toString()]), style: TextStyle(color: (product.quantity ?? 0) > 0 ? Colors.green : Colors.red),),
                            onTap: () => widget.onProductSelected(product),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
