import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../model/store.dart';
import '../model/product.dart';
import '../services/offline_data_service.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import 'product_details.dart';
import 'product_view.dart';

class InventoryPage extends StatefulWidget {
  final Store store;

  const InventoryPage({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  bool _isSearching = false;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilterKey = 'all';
  List<Product> _products = [];
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadProducts() async {
    try {
      final products =
          await OfflineDataService.getProductsForStore(widget.store.id);
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });

      // Check for low stock and send notifications
      _checkLowStockAndNotify();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    }
  }

  void _checkLowStockAndNotify() {
    final notificationService = NotificationService();

    for (final product in _products) {
      final quantity = product.quantity ?? 0;
      final lowStockAlert = product.lowStockAlert ?? 0;

      // Send notification if stock is low
      if (quantity > 0 && quantity <= lowStockAlert) {
        notificationService.showLowStockAlert(
          productName: product.name,
          quantity: quantity.toInt(),
          threshold: lowStockAlert.toInt(),
        );
      }
    }
  }

  void _onSearchChanged() {
    _filterProducts();
  }

  void _filterProducts() {
    final searchTerm = _searchController.text.toLowerCase();
    final filterKey = _selectedFilterKey;

    setState(() {
      _filteredProducts = _products.where((product) {
        // Search filter
        final matchesSearch = searchTerm.isEmpty ||
            product.name.toLowerCase().contains(searchTerm) ||
            (product.sku?.toLowerCase().contains(searchTerm) ?? false) ||
            (product.productCode?.toLowerCase().contains(searchTerm) ?? false);

        // Status filter
        final matchesFilter = _matchesFilter(product, filterKey);

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  bool _matchesFilter(Product product, String filterKey) {
    final quantity = product.quantity ?? 0;
    final lowStockAlert = product.lowStockAlert ?? 0;

    switch (filterKey) {
      case 'in_stock':
        return quantity > lowStockAlert;
      case 'low_stock':
        return quantity > 0 && quantity <= lowStockAlert;
      case 'out_of_stock':
        return quantity <= 0;
      case 'all':
      default:
        return true;
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.warning_rounded,
                  color: Colors.red.shade600, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Futa Bidhaa'),
          ],
        ),
        content: Text('Una uhakika unataka kufuta "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Ghairi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Futa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.deleteProduct(product.id!);
        setState(() {
          _products.removeWhere((p) => p.id == product.id);
          _filterProducts();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bidhaa imefutwa kwa mafanikio'),
            backgroundColor: Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imeshindwa kufuta bidhaa: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ProductDetailsPage(storeId: widget.store.id)),
          );
          if (result == true) {
            _loadProducts();
          }
        },
        backgroundColor: const Color(0xFF00C853),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('inventory.add_item'.tr(),
            style: const TextStyle(color: Colors.white)),
        tooltip: 'inventory.add_item'.tr(),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'inventory.search_items'.tr(),
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 16,
                  ),
                ),
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                ),
                autofocus: true,
              )
            : Text(
                'dashboard.inventory'.tr(),
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF1A1A1A),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Color(0xFF1A1A1A),
              ),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                });
              },
            )
          else
            IconButton(
              icon: const Icon(
                Icons.search,
                color: Color(0xFF1A1A1A),
              ),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Chips
              _buildFilterChips(),
              const SizedBox(height: 24),

              // Product Cards
              Expanded(
                child: SingleChildScrollView(
                  child: _buildProductCards(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filterKeys = ['all', 'in_stock', 'low_stock', 'out_of_stock'];
    final filters = filterKeys.map((key) => key.tr()).toList();
    final Map<String, Color> filterColors = {
      'all': Colors.grey.shade600,
      'in_stock': const Color(0xFF00C853),
      'low_stock': Colors.orange,
      'out_of_stock': Colors.red,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final filter = filters[index];
          final key = filterKeys[index];
          final color = filterColors[key]!;
          return Container(
            margin:
                EdgeInsets.only(right: index < filters.length - 1 ? 8.0 : 0),
            child: FilterChip(
              label: Text(filter),
              selected: _selectedFilterKey == key,
              onSelected: (bool selected) {
                setState(() {
                  _selectedFilterKey = selected ? key : 'all';
                  _filterProducts();
                });
              },
              backgroundColor: Colors.white,
              selectedColor: color.withOpacity(0.1),
              checkmarkColor: color,
              labelStyle: TextStyle(
                color: _selectedFilterKey == key ? color : Colors.grey.shade600,
                fontWeight: _selectedFilterKey == key
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color:
                      _selectedFilterKey == key ? color : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProductCards() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first product',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '${_filteredProducts.length} Products',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _filteredProducts
              .map((product) => _buildProductCard(product))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    final quantity = product.quantity ?? 0;
    final lowStockAlert = product.lowStockAlert ?? 0;

    Color borderColor = Colors.grey.shade200;
    if (quantity <= 0) {
      borderColor = Colors.red; // Out of stock
    } else if (quantity <= lowStockAlert) {
      borderColor = Colors.orange; // Low stock
    }
    // For in stock (quantity > lowStockAlert), keep grey

    return SizedBox(
      width: (MediaQuery.of(context).size.width - 20 * 2 - 12) /
          2, // Account for padding and spacing
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductViewPage(
                storeId: widget.store.id, productId: product.id),
          ),
        ).then((result) {
          if (result == true) {
            _loadProducts();
          }
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: product.media != null && product.media!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          product.media!.first.mediaUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey.shade600,
                              size: 48,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.grey.shade600,
                        size: 48,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock: $quantity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (quantity <= lowStockAlert && quantity > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Low Stock!',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else if (quantity <= 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Out of Stock!',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${product.sellingPrice} TZS',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF00C853),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
