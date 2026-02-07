import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../model/store.dart';
import '../model/category.dart';
import '../model/product.dart';
import '../services/supabase_service.dart';
import 'product_view.dart';

class CategoryPage extends StatefulWidget {
  final Store store;

  const CategoryPage({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Category> _categories = [];
  Map<String, List<SubCategory>> _subcategories = {};
  Map<String, List<Product>> _categoryProducts = {};
  bool _isLoading = true;
  String? _selectedCategoryId;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories =
          await SupabaseService.getCategoriesForStore(widget.store.id);
      setState(() => _categories = categories);

      // Load subcategories for all categories to show counts immediately
      await _loadAllSubcategories(categories);
    } catch (e) {
      _showSnackBar('Error loading categories: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllSubcategories(List<Category> categories) async {
    try {
      final subcategoryMap = <String, List<SubCategory>>{};

      // Load subcategories for each category
      for (final category in categories) {
        try {
          final subcategories =
              await SupabaseService.getSubCategoriesForCategory(category.id);
          subcategoryMap[category.id] = subcategories;
        } catch (e) {
          // Continue loading other categories even if one fails
          print('Error loading subcategories for category ${category.id}: $e');
        }
      }

      setState(() => _subcategories = subcategoryMap);
    } catch (e) {
      _showSnackBar('Error loading subcategories: $e', isError: true);
    }
  }

  Future<void> _loadSubcategories(String categoryId) async {
    try {
      final subcategories =
          await SupabaseService.getSubCategoriesForCategory(categoryId);
      setState(() => _subcategories[categoryId] = subcategories);
    } catch (e) {
      _showSnackBar('Error loading subcategories: $e', isError: true);
    }
  }

  Future<void> _loadCategoryProducts(String categoryId) async {
    try {
      final products = await SupabaseService.getProductsForStore(
        widget.store.id,
        categoryId: categoryId,
      );
      setState(() => _categoryProducts[categoryId] = products);
    } catch (e) {
      _showSnackBar('Error loading products: $e', isError: true);
    }
  }

  Future<void> _addSubcategory() async {
    if (_selectedCategoryId == null) return;

    final result = await showDialog<SubCategory?>(
      context: context,
      builder: (context) => const SubCategoryFormDialog(),
    );

    if (result != null) {
      try {
        final newSubcategory = await SupabaseService.addSubCategory(
          categoryId: _selectedCategoryId!,
          storeId: widget.store.id,
          name: result.name,
          description: result.description,
        );
        setState(() {
          _subcategories[_selectedCategoryId!] ??= [];
          _subcategories[_selectedCategoryId!]!.add(newSubcategory);
        });
        _showSnackBar('Subcategory added successfully');
      } catch (e) {
        _showSnackBar('Error adding subcategory: $e', isError: true);
      }
    }
  }

  Future<void> _editSubcategory(SubCategory subcategory) async {
    final result = await showDialog<SubCategory?>(
      context: context,
      builder: (context) => SubCategoryFormDialog(subcategory: subcategory),
    );

    if (result != null) {
      try {
        final updatedSubcategory = await SupabaseService.updateSubCategory(
          subCategoryId: subcategory.id,
          name: result.name,
          description: result.description,
        );
        final categorySubs = _subcategories[_selectedCategoryId!] ?? [];
        final index = categorySubs.indexWhere((s) => s.id == subcategory.id);
        if (index != -1) {
          setState(() => categorySubs[index] = updatedSubcategory);
        }
        _showSnackBar('Subcategory updated successfully');
      } catch (e) {
        _showSnackBar('Error updating subcategory: $e', isError: true);
      }
    }
  }

  Future<void> _deleteSubcategory(SubCategory subcategory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subcategory'),
        content:
            const Text('Are you sure you want to delete this subcategory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.deleteSubCategory(subcategory.id);
        setState(() {
          _subcategories[_selectedCategoryId!]!
              .removeWhere((s) => s.id == subcategory.id);
        });
        _showSnackBar('Subcategory deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting subcategory: $e', isError: true);
      }
    }
  }

  void _selectCategory(String categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _loadSubcategories(categoryId);
    _loadCategoryProducts(categoryId);
  }

  void _goBackToCategories() {
    setState(() {
      _selectedCategoryId = null;
      _isSearching = false;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  List<Category> get _filteredCategories {
    if (_searchQuery.isEmpty) return _categories;
    return _categories
        .where((category) =>
            category.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (category.description
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false))
        .toList();
  }

  List<SubCategory> get _filteredSubcategories {
    if (_selectedCategoryId == null || _searchQuery.isEmpty) {
      return _subcategories[_selectedCategoryId!] ?? [];
    }
    return (_subcategories[_selectedCategoryId!] ?? [])
        .where((subcategory) =>
            subcategory.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (subcategory.description
                    ?.toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false))
        .toList();
  }

  Future<void> _addCategory() async {
    final result = await showDialog<Category?>(
      context: context,
      builder: (context) => const CategoryFormDialog(),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final newCategory = await SupabaseService.addCategory(
          storeId: widget.store.id,
          name: result.name,
          description: result.description,
        );
        setState(() => _categories.add(newCategory));
        _showSnackBar('Category added successfully');
      } catch (e) {
        _showSnackBar('Error adding category: $e', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editCategory(Category category) async {
    final result = await showDialog<Category?>(
      context: context,
      builder: (context) => CategoryFormDialog(category: category),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final updatedCategory = await SupabaseService.updateCategory(
          categoryId: category.id,
          name: result.name,
          description: result.description,
        );
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          setState(() => _categories[index] = updatedCategory);
        }
        _showSnackBar('Category updated successfully');
      } catch (e) {
        _showSnackBar('Error updating category: $e', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteDialog(),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await SupabaseService.deleteCategory(category.id);
        setState(() => _categories.removeWhere((c) => c.id == category.id));
        _showSnackBar('Category deleted successfully');
      } catch (e) {
        _showSnackBar('Error deleting category: $e', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Colors.red.shade600 : const Color(0xFF00C853),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildDeleteDialog() {
    return AlertDialog(
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
          Text('categories.delete_category'.tr()),
        ],
      ),
      content: Text('categories.confirm_delete'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text('categories.cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text('categories.delete_category'.tr()),
        ),
      ],
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
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _selectedCategoryId != null
                      ? 'Tafuta jamii ndogo...'
                      : 'Tafuta jamii...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                  ),
                ),
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                ),
                autofocus: true,
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : Text(
                _selectedCategoryId != null
                    ? 'Jamii ndogo'
                    : 'categories.title'.tr(),
                style: const TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
        leading: _selectedCategoryId != null && !_isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
                onPressed: _goBackToCategories,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
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
                  _searchQuery = '';
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
                setState(() => _isSearching = true);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF00C853)))
                    : _selectedCategoryId != null
                        ? _buildSubcategoriesView()
                        : _categories.isEmpty
                            ? _buildEmptyState()
                            : _buildCategoriesList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedCategoryId != null
                      ? _addSubcategory
                      : _addCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _selectedCategoryId != null
                        ? 'Ongeza jamii ndogo'
                        : 'Ongeza jamii',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductViewPage(
                storeId: widget.store.id,
                productId: product.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
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
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.grey.shade400,
                            size: 32,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.grey.shade400,
                        size: 32,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${product.sellingPrice} TZS',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'categories.no_categories'.tr(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'categories.add_first_category'.tr(),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    final filteredCategories = _filteredCategories;
    return filteredCategories.isEmpty && _searchQuery.isNotEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Hakuna jamii zilizopatikana',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Jaribu neno lingine la utafutaji',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        : GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: filteredCategories.length,
            itemBuilder: (context, index) =>
                _buildCategoryCard(filteredCategories[index]),
          );
  }

  Widget _buildCategoryCard(Category category) {
    return InkWell(
      onTap: () => _selectCategory(category.id),
      onLongPress: () => _editCategory(category),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardImage(category),
            Expanded(child: _buildCardContent(category)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(Category category) {
    // List of icons to cycle through for visual variety
    final icons = [
      Icons.category_rounded,
      Icons.inventory_2_rounded,
      Icons.shopping_bag_rounded,
      Icons.restaurant_rounded,
      Icons.local_drink_rounded,
      Icons.kitchen_rounded,
      Icons.cleaning_services_rounded,
      Icons.build_rounded,
      Icons.sports_soccer_rounded,
      Icons.devices_rounded,
    ];

    // Use category name hash to consistently pick an icon
    final iconIndex = category.name.hashCode % icons.length;
    final selectedIcon = icons[iconIndex];

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Icon(selectedIcon, color: Colors.grey.shade500, size: 48),
    );
  }

  Widget _buildCardContent(Category category) {
    final subcategoryCount = _subcategories[category.id]?.length ?? 0;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subcategoryCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$subcategoryCount',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00C853),
                    ),
                  ),
                ),
            ],
          ),
          if (category.description?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(
              category.description!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                icon: Icons.edit_rounded,
                color: const Color(0xFF00C853),
                onPressed: () => _editCategory(category),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: Icons.delete_rounded,
                color: Colors.red.shade600,
                onPressed: () => _deleteCategory(category),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildSubcategoriesView() {
    final filteredSubcategories = _filteredSubcategories;
    final products = _categoryProducts[_selectedCategoryId] ?? [];

    return Column(
      children: [
        // Products Section
        if (products.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    size: 20, color: Color(0xFF00C853)),
                const SizedBox(width: 8),
                Text(
                  'Bidhaa (${products.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) =>
                  _buildProductCard(products[index]),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
        ],
        // Subcategories Section
        if (filteredSubcategories.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const Icon(Icons.subdirectory_arrow_right_outlined,
                    size: 20, color: Color(0xFF00C853)),
                const SizedBox(width: 8),
                Text(
                  'Jamii Ndogo (${filteredSubcategories.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (filteredSubcategories.isEmpty &&
            _searchQuery.isEmpty &&
            products.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.subdirectory_arrow_right_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Hakuna jamii ndogo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ongeza jamii ndogo yako ya kwanza',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else if (filteredSubcategories.isEmpty && _searchQuery.isNotEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hakuna jamii ndogo zilizopatikana',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jaribu neno lingine la utafutaji',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: filteredSubcategories.length,
              itemBuilder: (context, index) =>
                  _buildSubcategoryItem(filteredSubcategories[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildSubcategoryItem(SubCategory subcategory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00C853).withOpacity(0.1),
          child: Text(
            subcategory.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF00C853),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          subcategory.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: subcategory.description?.isNotEmpty ?? false
            ? Text(
                subcategory.description!,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF00C853), size: 20),
              onPressed: () => _editSubcategory(subcategory),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteSubcategory(subcategory),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class SubCategoryFormDialog extends StatefulWidget {
  final SubCategory? subcategory;

  const SubCategoryFormDialog({Key? key, this.subcategory}) : super(key: key);

  @override
  State<SubCategoryFormDialog> createState() => _SubCategoryFormDialogState();
}

class _SubCategoryFormDialogState extends State<SubCategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.subcategory != null) {
      _nameController.text = widget.subcategory!.name;
      _descriptionController.text = widget.subcategory!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Jina la jamii ndogo',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Jina linahitajika';
                }
                if (value!.trim().length < 2) {
                  return 'Jina fupi sana';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Maelezo (si lazima)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ghairi'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
          ),
          child: const Text('Hifadhi'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final subcategory = SubCategory(
        id: widget.subcategory?.id ?? '',
        categoryId: widget.subcategory?.categoryId ?? '',
        storeId: widget.subcategory?.storeId ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: widget.subcategory?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      Navigator.of(context).pop(subcategory);
    }
  }
}

class CategoryFormDialog extends StatefulWidget {
  final Category? category;

  const CategoryFormDialog({Key? key, this.category}) : super(key: key);

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Jina la jamii',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value?.trim().isEmpty ?? true) {
                  return 'Jina linahitajika';
                }
                if (value!.trim().length < 2) {
                  return 'Jina fupi sana';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Maelezo (si lazima)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ghairi'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
          ),
          child: const Text('Hifadhi'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final category = Category(
        id: widget.category?.id ?? '',
        storeId: widget.category?.storeId ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: widget.category?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      Navigator.of(context).pop(category);
    }
  }
}
