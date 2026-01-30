import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/product.dart';
import '../services/supabase_service.dart';
import '../widgets/debug_media_widget.dart';
import 'product_details.dart';

class ProductViewPage extends StatefulWidget {
  final String? storeId;
  final String? productId;

  const ProductViewPage({
    super.key,
    this.storeId,
    this.productId,
  });

  @override
  State<ProductViewPage> createState() => _ProductViewPageState();
}

class _ProductViewPageState extends State<ProductViewPage> {
  Product? product;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    if (widget.productId == null) return;

    try {
      // Fetch complete product data including media from database
      final product = await SupabaseService.getProductById(widget.productId!);
      setState(() {
        this.product = product;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
        title: Text(
          'products.product_details'.tr(),
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          title: Text(
            'products.product_details'.tr(),
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(child: Text('products.product_not_found'.tr())),
      );
    }

    final quantity = product!.quantity ?? 0;
    final lowStockAlert = product!.lowStockAlert ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: Text(
          'products.product_details'.tr(),
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ProductDetailsPage(
                    storeId: widget.storeId,
                    productId: widget.productId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit, color: Color(0xFF00C853)),
            label: Text(
              'products.edit'.tr(),
              style: const TextStyle(color: Color(0xFF00C853)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Images
              if (product!.media != null && product!.media!.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: product!.media!.length,
                    itemBuilder: (context, index) {
                      final media = product!.media![index];
                      return Container(
                        width: 200,
                        margin: EdgeInsets.only(right: index < product!.media!.length - 1 ? 12 : 0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                        child: media.mediaType == 'image'
                            ? Image.network(
                                media.mediaUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                              )
                              : const Icon(
                                  Icons.video_file,
                                  color: Colors.grey,
                                  size: 48,
                                ),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                    size: 64,
                  ),
                ),
              const SizedBox(height: 24),

              // Product Name
              Text(
                product!.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),

              // Stock Status and Price
              Row(
                children: [
              // Stock Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: quantity <= 0
                      ? Colors.red.withOpacity(0.1)
                      : quantity <= lowStockAlert
                          ? Colors.orange.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  quantity <= 0
                      ? 'products.out_of_stock'.tr()
                      : quantity <= lowStockAlert
                          ? 'products.low_stock'.tr()
                          : 'products.in_stock'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: quantity <= 0
                        ? Colors.red
                        : quantity <= lowStockAlert
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
              ),
                  const Spacer(),
                  // Price
                  Text(
                    '${product!.sellingPrice} TZS',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00C853),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stock Information
              Container(
                padding: const EdgeInsets.all(16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'products.current_stock'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    if (lowStockAlert > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'products.low_stock_alert'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            '$lowStockAlert',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Product Details
              Text(
                'products.product_information'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),

              // Information Cards
              if (product!.sku != null && product!.sku!.isNotEmpty)
                _buildInfoRow('SKU', product!.sku!),
              if (product!.productCode != null && product!.productCode!.isNotEmpty)
                _buildInfoRow('Product Code', product!.productCode!),
              if (product!.costPrice != null)
                _buildInfoRow('Cost Price', '${product!.costPrice} TZS'),
              if (product!.wholesalePrice != null)
                _buildInfoRow('Wholesale Price', '${product!.wholesalePrice} TZS'),
              if (product!.discountPrice != null)
                _buildInfoRow('Discount Price', '${product!.discountPrice} TZS'),
              if (product!.supplierName != null && product!.supplierName!.isNotEmpty)
                _buildInfoRow('Supplier', product!.supplierName!),
              if (product!.batchNumber != null && product!.batchNumber!.isNotEmpty)
                _buildInfoRow('Batch Number', product!.batchNumber!),
              if (product!.expiryDate != null)
                _buildInfoRow('Expiry Date', product!.expiryDate!.toLocal().toString().split(' ')[0]),
              if (product!.supplierDate != null)
                _buildInfoRow('Supplier Date', product!.supplierDate!.toLocal().toString().split(' ')[0]),

              const SizedBox(height: 24),

              // Description
              if (product!.description != null && product!.description!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'products.description'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    product!.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
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
}
