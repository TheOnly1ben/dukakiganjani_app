import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../model/product.dart';
import '../model/category.dart';
import '../services/supabase_service.dart';
import '../services/offline_data_service.dart';

class ProductDetailsPage extends StatefulWidget {
  final String? storeId;
  final String? productId; // For editing existing product

  const ProductDetailsPage({
    super.key,
    this.storeId,
    this.productId,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // Required fields controllers
  late final TextEditingController nameController;
  late final TextEditingController priceController;
  late final TextEditingController costPriceController;
  late final TextEditingController quantityController;
  late final TextEditingController lowStockAlertController;

  // Optional fields controllers
  late final TextEditingController wholesalePriceController;
  late final TextEditingController discountPriceController;
  late final TextEditingController descriptionController;
  late final TextEditingController supplierNameController;
  late final TextEditingController expiryDateController;
  late final TextEditingController batchNumberController;
  late final TextEditingController skuController;
  late final TextEditingController productCodeController;
  late final TextEditingController supplierDateController;

  // State
  bool isLoading = false;
  bool showOptionalFields = false;
  Product? existingProduct;
  List<Category> categories = [];
  List<SubCategory> subCategories = [];
  String? selectedCategoryId;
  String? selectedSubCategoryId;
  List<XFile?> selectedImages = [
    null,
    null
  ]; // Changed to XFile for image picker
  List<ProductMedia> existingImages = []; // Existing images from database
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    // Required fields
    nameController = TextEditingController();
    priceController = TextEditingController();
    costPriceController = TextEditingController();
    quantityController = TextEditingController();
    lowStockAlertController = TextEditingController();

    // Optional fields
    wholesalePriceController = TextEditingController();
    discountPriceController = TextEditingController();
    descriptionController = TextEditingController();
    supplierNameController = TextEditingController();
    expiryDateController = TextEditingController();
    batchNumberController = TextEditingController();
    skuController = TextEditingController();
    productCodeController = TextEditingController();
    supplierDateController = TextEditingController();
  }

  Future<void> _loadData() async {
    if (widget.storeId == null) return;

    setState(() => isLoading = true);

    try {
      // Load categories
      categories =
          await OfflineDataService.getCategoriesForStore(widget.storeId!);

      // Load existing product if editing
      if (widget.productId != null) {
        existingProduct =
            await SupabaseService.getProductById(widget.productId!);
        _populateControllers();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _populateControllers() {
    if (existingProduct == null) return;

    nameController.text = existingProduct!.name;
    priceController.text = existingProduct!.sellingPrice.toString();
    quantityController.text = existingProduct!.quantity?.toString() ?? '0';

    costPriceController.text = existingProduct!.costPrice?.toString() ?? '';
    lowStockAlertController.text =
        existingProduct!.lowStockAlert?.toString() ?? '';
    wholesalePriceController.text =
        existingProduct!.wholesalePrice?.toString() ?? '';
    discountPriceController.text =
        existingProduct!.discountPrice?.toString() ?? '';
    descriptionController.text = existingProduct!.description ?? '';
    supplierNameController.text = existingProduct!.supplierName ?? '';
    expiryDateController.text =
        existingProduct!.expiryDate?.toIso8601String().split('T')[0] ?? '';
    batchNumberController.text = existingProduct!.batchNumber ?? '';
    skuController.text = existingProduct!.sku ?? '';
    productCodeController.text = existingProduct!.productCode ?? '';
    supplierDateController.text =
        existingProduct!.supplierDate?.toIso8601String().split('T')[0] ?? '';

    selectedCategoryId = existingProduct!.categoryId;
    selectedSubCategoryId = existingProduct!.subCategoryId;

    // Load existing product images
    if (existingProduct!.media != null && existingProduct!.media!.isNotEmpty) {
      existingImages = existingProduct!.media!;
    }

    // Load subcategories if category is selected
    if (selectedCategoryId != null) {
      _loadSubCategories(selectedCategoryId!);
    }
  }

  Future<void> _loadSubCategories(String categoryId) async {
    try {
      subCategories =
          await SupabaseService.getSubCategoriesForCategory(categoryId);
      setState(() {});
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _pickImage(int index) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image =
                      await _imagePicker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() {
                      selectedImages[index] = image;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image =
                      await _imagePicker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() {
                      selectedImages[index] = image;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title:
                    const Text('Remove', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    selectedImages[index] = null;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    costPriceController.dispose();
    lowStockAlertController.dispose();
    wholesalePriceController.dispose();
    discountPriceController.dispose();
    descriptionController.dispose();
    supplierNameController.dispose();
    expiryDateController.dispose();
    batchNumberController.dispose();
    skuController.dispose();
    productCodeController.dispose();
    supplierDateController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (widget.storeId == null) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final productData = Product(
        id: existingProduct?.id,
        storeId: widget.storeId!,
        categoryId: selectedCategoryId,
        subCategoryId: selectedSubCategoryId,
        name: nameController.text.trim(),
        sku: skuController.text.isNotEmpty ? skuController.text.trim() : null,
        productCode: productCodeController.text.isNotEmpty
            ? productCodeController.text.trim()
            : null,
        costPrice: costPriceController.text.isNotEmpty
            ? double.tryParse(costPriceController.text)
            : null,
        sellingPrice: double.parse(priceController.text),
        wholesalePrice: wholesalePriceController.text.isNotEmpty
            ? double.tryParse(wholesalePriceController.text)
            : null,
        discountPrice: discountPriceController.text.isNotEmpty
            ? double.tryParse(discountPriceController.text)
            : null,
        quantity: double.parse(quantityController.text),
        lowStockAlert: lowStockAlertController.text.isNotEmpty
            ? int.parse(lowStockAlertController.text)
            : null,
        description: descriptionController.text.isNotEmpty
            ? descriptionController.text.trim()
            : null,
        supplierName: supplierNameController.text.isNotEmpty
            ? supplierNameController.text.trim()
            : null,
        expiryDate: expiryDateController.text.isNotEmpty
            ? DateTime.parse(expiryDateController.text)
            : null,
        batchNumber: batchNumberController.text.isNotEmpty
            ? batchNumberController.text.trim()
            : null,
        supplierDate: supplierDateController.text.isNotEmpty
            ? DateTime.parse(supplierDateController.text)
            : null,
      );

      late Product savedProduct;

      if (existingProduct != null) {
        // Update existing product
        savedProduct = await OfflineDataService.updateProductWithParams(
          productId: existingProduct!.id!,
          categoryId: productData.categoryId,
          subCategoryId: productData.subCategoryId,
          name: productData.name,
          sku: productData.sku,
          productCode: productData.productCode,
          costPrice: productData.costPrice,
          sellingPrice: productData.sellingPrice,
          wholesalePrice: productData.wholesalePrice,
          discountPrice: productData.discountPrice,
          quantity: productData.quantity?.toInt(),
          lowStockAlert: productData.lowStockAlert,
          description: productData.description,
          supplierName: productData.supplierName,
          expiryDate: productData.expiryDate,
          batchNumber: productData.batchNumber,
          supplierDate: productData.supplierDate,
        );

        // Handle image uploads for existing product
        await _uploadSelectedImages(savedProduct.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('products.product_updated'.tr())),
        );
        Navigator.of(context).pop(true);
        return;
      } else {
        // Add new product
        savedProduct = await OfflineDataService.addProductWithParams(
          storeId: widget.storeId!,
          categoryId: productData.categoryId,
          subCategoryId: productData.subCategoryId,
          name: productData.name,
          sku: productData.sku,
          productCode: productData.productCode,
          costPrice: productData.costPrice ?? 0.0,
          sellingPrice: productData.sellingPrice,
          wholesalePrice: productData.wholesalePrice,
          discountPrice: productData.discountPrice,
          quantity: productData.quantity?.toInt() ?? 0,
          lowStockAlert: productData.lowStockAlert,
          description: productData.description,
          supplierName: productData.supplierName,
          expiryDate: productData.expiryDate,
          batchNumber: productData.batchNumber,
          supplierDate: productData.supplierDate,
        );

        // Upload selected images for new product
        debugPrint(
            '📸 Attempting to upload ${selectedImages.where((img) => img != null).length} images...');
        await _uploadSelectedImages(savedProduct.id!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('products.product_added'.tr())),
        );
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving product: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _uploadSelectedImages(String productId) async {
    // Upload all selected images to Supabase Storage and save to product_media table
    int successCount = 0;
    int failCount = 0;

    for (int i = 0; i < selectedImages.length; i++) {
      final image = selectedImages[i];
      if (image != null) {
        try {
          await SupabaseService.uploadProductMedia(
            productId: productId,
            storeId: widget.storeId!,
            filePath: image.path,
            fileName: image.name,
            mediaType: 'image',
            isPrimary: i == 0, // First image is primary
          );
          successCount++;
        } catch (e) {
          failCount++;
          print('Error uploading image $i: $e');
          // Show error to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Picha $i haikuweza kuhifadhiwa: $e'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    }

    // Show summary if any images were attempted
    if (successCount > 0 || failCount > 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              successCount > 0
                  ? 'Picha $successCount zimehifadhiwa!'
                  : 'Picha zote zimeshindwa kuhifadhiwa!',
            ),
            backgroundColor: successCount > 0 ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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
          existingProduct != null
              ? 'products.edit_product'.tr()
              : 'products.add_product'.tr(),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Section - Show existing images + ability to add new ones
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: existingImages.length +
                              2, // existing + 2 new slots
                          itemBuilder: (context, index) {
                            // Show existing images first
                            if (index < existingImages.length) {
                              final media = existingImages[index];
                              return Container(
                                width: 80,
                                margin: EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 0.5,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        media.mediaUrl,
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey.shade600,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            existingImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Show new image slots
                            final newImageIndex = index - existingImages.length;
                            final image = selectedImages[newImageIndex];
                            return GestureDetector(
                              onTap: () => _pickImage(newImageIndex),
                              child: Container(
                                width: 80,
                                margin: EdgeInsets.only(
                                    right: newImageIndex < 1 ? 8 : 0),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 0.5,
                                  ),
                                ),
                                child: image != null
                                    ? Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.file(
                                              File(image.path),
                                              fit: BoxFit.cover,
                                              width: 80,
                                              height: 80,
                                            ),
                                          ),
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedImages[
                                                      newImageIndex] = null;
                                                });
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_outlined,
                                            color: Colors.grey.shade600,
                                            size: 24,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'products.add_image'.tr(),
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Required Fields Section
                      Text(
                        'products.required_information'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Product Name (Required)
                      TextFormField(
                        controller: nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'products.product_name_required'.tr();
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'products.product_name'.tr(),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF00C853), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selling Price (Required)
                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'products.selling_price_required'.tr();
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'products.valid_selling_price_required'.tr();
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'products.selling_price'.tr(),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF00C853), width: 1.5),
                          ),
                          suffixText: 'TZS',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cost Price (Required)
                      TextFormField(
                        controller: costPriceController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'products.cost_price_required'.tr();
                          }
                          final price = double.tryParse(value);
                          if (price == null || price < 0) {
                            return 'products.valid_cost_price_required'.tr();
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'products.cost_price'.tr(),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF00C853), width: 1.5),
                          ),
                          suffixText: 'TZS',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Quantity (Required)
                      TextFormField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'products.quantity_required'.tr();
                          }
                          final qty = double.tryParse(value);
                          if (qty == null || qty < 0) {
                            return 'products.valid_quantity_required'.tr();
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'products.stock_quantity'.tr(),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF00C853), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Low Stock Alert (Required)
                      TextFormField(
                        controller: lowStockAlertController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'products.low_stock_alert_required'.tr();
                          }
                          final alert = int.tryParse(value);
                          if (alert == null || alert < 0) {
                            return 'products.valid_number_required'.tr();
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'products.low_stock_alert'.tr(),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF00C853), width: 1.5),
                          ),
                          hintText: 'e.g., 5',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category (Required section, not mandatory)
                      DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: 'products.category'.tr(),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: Colors.grey.shade300, width: 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                                color: Color(0xFF00C853), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        items: categories.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategoryId = value;
                            selectedSubCategoryId = null; // Reset subcategory
                            if (value != null) {
                              _loadSubCategories(value);
                            } else {
                              subCategories = [];
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sub Category (Required section, not mandatory)
                      if (selectedCategoryId != null &&
                          subCategories.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: selectedSubCategoryId,
                          decoration: InputDecoration(
                            labelText: 'products.subcategory'.tr(),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                  color: Colors.grey.shade300, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                  color: Color(0xFF00C853), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          items: subCategories.map((subCategory) {
                            return DropdownMenuItem(
                              value: subCategory.id,
                              child: Text(subCategory.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedSubCategoryId = value;
                            });
                          },
                        ),
                      if (selectedCategoryId != null &&
                          subCategories.isNotEmpty)
                        const SizedBox(height: 24),
                      if (selectedCategoryId == null || subCategories.isEmpty)
                        const SizedBox(height: 24),

                      // Optional Fields Toggle
                      InkWell(
                        onTap: () {
                          setState(() {
                            showOptionalFields = !showOptionalFields;
                          });
                        },
                        child: Row(
                          children: [
                            Text(
                              'products.optional_information'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              showOptionalFields
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Optional Fields
                      if (showOptionalFields) ...[
                        // SKU
                        TextFormField(
                          controller: skuController,
                          decoration: InputDecoration(
                            labelText: 'products.sku'.tr(),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF00C853), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Product Code
                        TextFormField(
                          controller: productCodeController,
                          decoration: InputDecoration(
                            labelText: 'products.product_code'.tr(),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF00C853), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Wholesale Price
                        TextFormField(
                          controller: wholesalePriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'products.wholesale_price'.tr(),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF00C853), width: 2),
                            ),
                            suffixText: 'TZS',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Discount Price
                        TextFormField(
                          controller: discountPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'products.discount_price'.tr(),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF00C853), width: 2),
                            ),
                            suffixText: 'TZS',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Supplier Name
                        TextFormField(
                          controller: supplierNameController,
                          decoration: InputDecoration(
                            labelText: 'products.supplier_name'.tr(),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF00C853), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Expiry Date
                        TextFormField(
                          controller: expiryDateController,
                          decoration: InputDecoration(
                            labelText: 'products.expiry_date'.tr(),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF00C853), width: 2),
                            ),
                            hintText: 'YYYY-MM-DD',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now()
                                  .add(const Duration(days: 365 * 10)),
                            );
                            if (date != null) {
                              expiryDateController.text =
                                  date.toIso8601String().split('T')[0];
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Batch Number
                        TextFormField(
                          controller: batchNumberController,
                          decoration: InputDecoration(
                            labelText: 'products.batch_number'.tr(),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF00C853), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Supplier Date
                        TextFormField(
                          controller: supplierDateController,
                          decoration: InputDecoration(
                            labelText: 'products.supplier_date'.tr(),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF00C853), width: 2),
                            ),
                            hintText: 'YYYY-MM-DD',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              supplierDateController.text =
                                  date.toIso8601String().split('T')[0];
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Description
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'products.description'.tr(),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF00C853), width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text('products.cancel'.tr()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _saveProduct,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C853),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Text(existingProduct != null
                                      ? 'products.save'.tr()
                                      : 'products.add'.tr()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final List<String?> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        itemCount: images.length,
        controller: PageController(initialPage: initialIndex),
        itemBuilder: (context, index) {
          return Center(
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          );
        },
      ),
    );
  }
}
