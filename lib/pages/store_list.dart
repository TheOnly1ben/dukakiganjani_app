import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../model/store.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import 'dashboard.dart';

class StoreListPage extends StatefulWidget {
  const StoreListPage({Key? key}) : super(key: key);

  @override
  State<StoreListPage> createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  final _addStoreFormKey = GlobalKey<FormState>();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storeDescriptionController =
      TextEditingController();
  final TextEditingController _storeLocationController =
      TextEditingController();
  final TextEditingController _customTypeController = TextEditingController();

  String? _selectedStoreType;
  bool _isOtherSelected = false;
  bool _isLoading = true;
  bool _isAddingStore = false;
  bool _isUpdatingStore = false;
  List<Store> _stores = [];
  Store? _editingStore;

  final List<String> _storeTypes = [
    'Grocery Store',
    'Supermarket',
    'Pharmacy',
    'Restaurant',
    'Electronics Store',
    'Clothing Store',
    'Hardware Store',
    'Bookstore',
    'Bakery',
    'Jewelry Store',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    // Fix: Immediately set loading state to prevent UI from building with stale data.
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final stores = await SupabaseService.getStoresForUser();
      if (mounted) {
        setState(() {
          _stores = stores;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading stores: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00C853),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.logout,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () async {
            await authService.logout();
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
          },
        ),
        title: Text(
          'store_list.title'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'store_list.subtitle'.tr(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // Store List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _stores.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.store,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No stores found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button to add your first store',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _stores.length,
                            itemBuilder: (context, index) {
                              final store = _stores[index];
                              return _buildStoreCard(store);
                            },
                          ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showAddStoreBottomSheet(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'store_list.add_store'.tr(),
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

  Widget _buildStoreCard(Store store) {
    bool isActive = store.status == 'Active';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _navigateToStore(store),
          onLongPress: () => _showStoreActions(store),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.store,
                        color: Color(0xFF00C853),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  store.location ?? 'No location set',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF00C853).withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        store.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? const Color(0xFF00C853)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Color(0xFF1A1A1A),
                      ),
                      onPressed: () => _showStoreActions(store),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToStore(Store store) async {
    // Navigate to store dashboard, then reload stores on return to prevent state issues.
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OwnerDashboardPage(store: store),
      ),
    );
    // On return, trigger the reload with the proper loading state.
    _loadStores();
  }

  void _showStoreActions(Store store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                store.status == 'Active'
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: store.status == 'Active' ? Colors.orange : Colors.green,
              ),
              title: Text('store_list.toggle_status'.tr()),
              subtitle: Text(store.status == 'Active'
                  ? 'store_list.hide_from_customers'.tr()
                  : 'store_list.show_to_customers'.tr()),
              onTap: () {
                Navigator.of(context).pop();
                _toggleStoreStatus(store);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF00C853)),
              title: Text('store_list.edit_store'.tr()),
              onTap: () {
                Navigator.of(context).pop();
                _showAddStoreBottomSheet(store: store);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('store_list.delete_store'.tr()),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteConfirmation(store);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Store store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('store_list.delete_store_title'.tr()),
        content: Text('store_list.delete_store_confirm'
            .tr()
            .replaceAll('{storeName}', store.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('store_list.cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteStore(store);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('store_list.delete_store'.tr()),
          ),
        ],
      ),
    );
  }

  void _showAddStoreBottomSheet({Store? store}) {
    // Set editing mode
    _editingStore = store;

    // Populate form if editing
    if (store != null) {
      _storeNameController.text = store.name;
      _storeDescriptionController.text = store.description ?? '';
      _storeLocationController.text = store.location ?? '';
      _selectedStoreType =
          _storeTypes.contains(store.type) ? store.type : 'Other';
      _isOtherSelected = _selectedStoreType == 'Other';
      if (_isOtherSelected) {
        _customTypeController.text = store.type;
      }
    } else {
      // Reset form state for adding
      _storeNameController.clear();
      _storeDescriptionController.clear();
      _storeLocationController.clear();
      _customTypeController.clear();
      _selectedStoreType = null;
      _isOtherSelected = false;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Form(
                  key: _addStoreFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.store,
                              color: Color(0xFF00C853),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _editingStore != null
                                      ? 'store_list.edit_store'.tr()
                                      : 'store_list.add_store'.tr(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                Text(
                                  _editingStore != null
                                      ? 'store_list.update_store_desc'.tr()
                                      : 'store_list.add_store_desc'.tr(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'store_list.store_name'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _storeNameController,
                        decoration: InputDecoration(
                          hintText: 'store_list.store_name_hint'.tr(),
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF00C853),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'store_list.store_name_required'.tr();
                          }
                          if (value.length < 2) {
                            return 'store_list.store_name_too_short'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'store_list.store_type'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedStoreType,
                        decoration: InputDecoration(
                          hintText: 'store_list.store_type_hint'.tr(),
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF00C853),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        items: _storeTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStoreType = value;
                            _isOtherSelected = value == 'Other';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'store_list.store_type_required'.tr();
                          }
                          return null;
                        },
                      ),
                      if (_isOtherSelected) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _customTypeController,
                          decoration: InputDecoration(
                            hintText: 'store_list.custom_type_hint'.tr(),
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 15,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF5F5F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF00C853),
                                width: 1.5,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (_isOtherSelected &&
                                (value == null || value.isEmpty)) {
                              return 'store_list.custom_type_required'.tr();
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        'Location',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _storeLocationController,
                        decoration: InputDecoration(
                          hintText:
                              'Enter store location (e.g., Dar es Salaam, Tanzania)',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF00C853),
                              width: 1.5,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: const Color(0xFF00C853),
                            size: 22,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'store_list.store_description'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _storeDescriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'store_list.store_description_hint'.tr(),
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF00C853),
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF00C853),
                                ),
                                foregroundColor: const Color(0xFF00C853),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('store_list.cancel'.tr()),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (_editingStore != null
                                      ? _isUpdatingStore
                                      : _isAddingStore)
                                  ? null
                                  : () => _editingStore != null
                                      ? _updateStore(context)
                                      : _addStore(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isAddingStore
                                    ? Colors.grey[400]
                                    : const Color(0xFF00C853),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: (_editingStore != null
                                      ? _isUpdatingStore
                                      : _isAddingStore)
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
                                  : Text(_editingStore != null
                                      ? 'store_list.update_store_button'.tr()
                                      : 'store_list.add_store_button'.tr()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addStore(BuildContext context) async {
    if (_addStoreFormKey.currentState!.validate()) {
      setState(() => _isAddingStore = true);

      try {
        // Determine final store type
        String finalStoreType = _selectedStoreType!;
        if (_isOtherSelected && _customTypeController.text.isNotEmpty) {
          finalStoreType = _customTypeController.text;
        }

        // Add store to database
        final newStore = await SupabaseService.addStore(
          name: _storeNameController.text,
          type: finalStoreType,
          description: _storeDescriptionController.text.isNotEmpty
              ? _storeDescriptionController.text
              : null,
          location: _storeLocationController.text.isNotEmpty
              ? _storeLocationController.text
              : null,
        );

        // Add to local list
        setState(() {
          _stores.insert(0, newStore);
        });

        // Close bottom sheet and clear form
        if (mounted) {
          Navigator.of(context).pop();
          _storeNameController.clear();
          _storeDescriptionController.clear();
          _storeLocationController.clear();
          _customTypeController.clear();
          _selectedStoreType = null;
          _isOtherSelected = false;
        }
      } catch (e) {
        print('Error adding store: $e');
      } finally {
        setState(() => _isAddingStore = false);
      }
    }
  }

  void _updateStore(BuildContext context) async {
    if (_addStoreFormKey.currentState!.validate()) {
      setState(() => _isUpdatingStore = true);

      try {
        // Determine final store type
        String finalStoreType = _selectedStoreType!;
        if (_isOtherSelected && _customTypeController.text.isNotEmpty) {
          finalStoreType = _customTypeController.text;
        }

        // Update store in database
        final updatedStore = await SupabaseService.updateStore(
          storeId: _editingStore!.id,
          name: _storeNameController.text,
          type: finalStoreType,
          description: _storeDescriptionController.text.isNotEmpty
              ? _storeDescriptionController.text
              : null,
          location: _storeLocationController.text.isNotEmpty
              ? _storeLocationController.text
              : null,
        );

        // Update in local list
        setState(() {
          final index =
              _stores.indexWhere((store) => store.id == _editingStore!.id);
          if (index != -1) {
            _stores[index] = updatedStore;
          }
        });

        // Close bottom sheet and clear form
        if (mounted) {
          Navigator.of(context).pop();
          _storeNameController.clear();
          _storeDescriptionController.clear();
          _storeLocationController.clear();
          _customTypeController.clear();
          _selectedStoreType = null;
          _isOtherSelected = false;
          _editingStore = null;
        }
      } catch (e) {
        print('Error updating store: $e');
      } finally {
        setState(() => _isUpdatingStore = false);
      }
    }
  }

  void _deleteStore(Store store) async {
    try {
      await SupabaseService.deleteStore(store.id);

      // Remove from local list
      setState(() {
        _stores.removeWhere((s) => s.id == store.id);
      });
    } catch (e) {
      print('Error deleting store: $e');
    }
  }

  void _toggleStoreStatus(Store store) async {
    try {
      final updatedStore = await SupabaseService.toggleStoreStatus(store.id);

      // Update in local list
      setState(() {
        final index = _stores.indexWhere((s) => s.id == store.id);
        if (index != -1) {
          _stores[index] = updatedStore;
        }
      });
    } catch (e) {
      print('Error toggling store status: $e');
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _storeLocationController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }
}
