import 'package:flutter/material.dart';

import '../../../../core/storage/local_json_storage.dart';
import '../../../configuration/data/datasources/configuration_local_datasource.dart';
import '../../../configuration/data/repositories/configuration_repository_impl.dart';
import '../../../configuration/domain/entities/member_entity.dart';
import '../../../configuration/domain/repositories/configuration_repository.dart';
import '../../data/datasources/product_local_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final ProductRepository _productRepository;
  late final ConfigurationRepository _configurationRepository;

  List<ProductEntity> _products = [];
  List<MemberEntity> _members = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final storage = LocalJsonStorage();

    _productRepository = ProductRepositoryImpl(
      ProductLocalDataSource(storage),
    );

    _configurationRepository = ConfigurationRepositoryImpl(
      ConfigurationLocalDataSource(storage),
    );

    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final products = await _productRepository.getProducts();
      final members = await _configurationRepository.getMembers();

      products.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;

      setState(() {
        _products = products;
        _members = members;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Unable to load products: $error');
    }
  }

  Future<void> _showProductDialog({
    ProductEntity? product,
  }) async {
    if (_members.where((member) => member.isActive).isEmpty &&
        product == null) {
      _showMessage('Please add an active member in Configuration first.');
      return;
    }

    final result = await showDialog<ProductEntity>(
      context: context,
      builder: (context) {
        return _ProductFormDialog(
          members: _members,
          product: product,
        );
      },
    );

    if (result == null) return;

    try {
      if (product == null) {
        await _productRepository.addProduct(result);
      } else {
        await _productRepository.updateProduct(result);
      }

      await _loadData();

      if (!mounted) return;

      _showMessage(
        product == null
            ? 'Product added successfully.'
            : 'Product updated successfully.',
      );
    } catch (error) {
      _showMessage('Unable to save product: $error');
    }
  }

  Future<void> _deleteProduct(ProductEntity product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete product?'),
          content: Text(
            'Are you sure you want to delete "${product.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _productRepository.deleteProduct(product.id);
      await _loadData();

      if (!mounted) return;

      _showMessage('Product deleted successfully.');
    } catch (error) {
      _showMessage('Unable to delete product: $error');
    }
  }

  String _memberNames(List<String> memberIds) {
    if (memberIds.isEmpty) return 'None';

    return memberIds.map((id) {
      final matchingMembers = _members.where(
        (member) => member.id == id,
      );

      if (matchingMembers.isEmpty) {
        return 'Unknown member';
      }

      return matchingMembers.first.name;
    }).join(', ');
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = _products.fold<double>(
      0,
      (total, product) => total + product.sellingPrice,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _products.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 140),
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No products added yet.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Tap Add Product to get started.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Products',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_products.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Total Selling Value',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatCurrency(totalValue),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Product History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._products.map(_buildProductCard),
                        const SizedBox(height: 80),
                      ],
                    ),
            ),
    );
  }

  Widget _buildProductCard(ProductEntity product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showProductDialog(product: product);
                    } else if (value == 'delete') {
                      _deleteProduct(product);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _formatCurrency(product.sellingPrice),
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9B6DFF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${_formatDate(product.date)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 24),
            const Text(
              'Effort Contributors',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(_memberNames(product.effortContributorIds)),
            if (product.effortContributorIds.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                product.resolvedEffortContributionPercentages.entries
                    .map((entry) {
                      final member = _members.where(
                        (item) => item.id == entry.key,
                      ).toList();
                      final name = member.isEmpty ? 'Unknown' : member.first.name;
                      return '$name: ${entry.value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '')}%';
                    })
                    .join(' • '),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Marketing Contributors',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(_memberNames(product.marketingContributorIds)),
          ],
        ),
      ),
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({
    required this.members,
    this.product,
  });

  final List<MemberEntity> members;
  final ProductEntity? product;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;

  late DateTime _selectedDate;

  late Set<String> _effortContributorIds;
  late Set<String> _marketingContributorIds;
  final Map<String, TextEditingController> _effortPercentageControllers = {};

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _nameController = TextEditingController(
      text: product?.name ?? '',
    );

    _priceController = TextEditingController(
      text: product?.sellingPrice.toString() ?? '',
    );

    _selectedDate = product?.date ?? DateTime.now();

    _effortContributorIds = {
      ...?product?.effortContributorIds,
    };

    _marketingContributorIds = {
      ...?product?.marketingContributorIds,
    };

    final initialPercentages =
        product?.resolvedEffortContributionPercentages ?? const <String, double>{};
    _resetEffortPercentages(initialPercentages);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    for (final controller in _effortPercentageControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  void _toggleMember(Set<String> selectedIds, String memberId) {
    setState(() {
      if (selectedIds.contains(memberId)) {
        selectedIds.remove(memberId);
      } else {
        selectedIds.add(memberId);
      }

      if (identical(selectedIds, _effortContributorIds)) {
        // Contributor changes require a fresh percentage distribution.
        _resetEffortPercentages(_equalEffortPercentages(_effortContributorIds));
      }
    });
  }

  Map<String, double> _equalEffortPercentages(Set<String> ids) {
    final sortedIds = ids.toList()..sort();
    if (sortedIds.isEmpty) return <String, double>{};
    final share = 100 / sortedIds.length;
    return <String, double>{
      for (var index = 0; index < sortedIds.length; index++)
        sortedIds[index]: index == sortedIds.length - 1
            ? 100 - share * (sortedIds.length - 1)
            : share,
    };
  }

  void _resetEffortPercentages(Map<String, double> values) {
    for (final controller in _effortPercentageControllers.values) {
      controller.dispose();
    }
    _effortPercentageControllers
      ..clear()
      ..addEntries(values.entries.map(
        (entry) => MapEntry(
          entry.key,
          TextEditingController(text: _formatPercentage(entry.value)),
        ),
      ));
  }

  String _formatPercentage(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  Widget _buildEffortPercentageFields() {
    final ids = _effortContributorIds.toList()..sort();
    if (ids.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Effort Percentage Distribution',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        const Text(
          'Set each contributor’s share of the effort pool. Total must be 100%.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        ...ids.map((id) {
          final matchingMembers =
              widget.members.where((item) => item.id == id).toList();
          final name = matchingMembers.isEmpty
              ? 'Unknown member'
              : matchingMembers.first.name;
          final controller = _effortPercentageControllers.putIfAbsent(
            id,
            () => TextEditingController(text: '0'),
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '$name (%)',
                suffixText: '%',
                isDense: true,
              ),
            ),
          );
        }),
      ],
    );
  }

  List<MemberEntity> _availableMembers(Set<String> selectedIds) {
    return widget.members.where((member) {
      return member.isActive || selectedIds.contains(member.id);
    }).toList();
  }

  Widget _buildContributorSection({
    required String title,
    required Set<String> selectedIds,
  }) {
    final availableMembers = _availableMembers(selectedIds);

    if (availableMembers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No active members available.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(
        '${selectedIds.length} selected',
        style: const TextStyle(fontSize: 12),
      ),
      children: availableMembers.map((member) {
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(member.name),
          subtitle: member.isActive
              ? null
              : const Text('Inactive member'),
          value: selectedIds.contains(member.id),
          onChanged: (_) {
            _toggleMember(selectedIds, member.id);
          },
        );
      }).toList(),
    );
  }

  void _saveProduct() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    if (name.isEmpty) {
      _showValidationMessage('Please enter a product name.');
      return;
    }

    if (price == null || !price.isFinite || price <= 0) {
      _showValidationMessage('Please enter a valid selling price.');
      return;
    }

    final effortPercentages = <String, double>{};
    for (final id in _effortContributorIds) {
      final value = double.tryParse(
        _effortPercentageControllers[id]?.text.trim() ?? '',
      );
      if (value == null || !value.isFinite || value < 0 || value > 100) {
        _showValidationMessage('Enter a valid effort percentage for each contributor.');
        return;
      }
      effortPercentages[id] = value;
    }

    final percentageTotal = effortPercentages.values.fold<double>(
      0,
      (total, value) => total + value,
    );
    if (effortPercentages.isNotEmpty &&
        (percentageTotal - 100).abs() > 0.000001) {
      _showValidationMessage('Effort percentages must total 100%. Current total: ${percentageTotal.toStringAsFixed(2)}%.');
      return;
    }

    final product = ProductEntity(
      id: widget.product?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      sellingPrice: price,
      date: _selectedDate,
      effortContributorIds: _effortContributorIds.toList(),
      marketingContributorIds: _marketingContributorIds.toList(),
      effortContributionPercentages: effortPercentages,
    );

    Navigator.pop(context, product);
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'Enter product name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Selling Price (₹)',
                  hintText: 'Enter selling price',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Product Date',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(_formatDate(_selectedDate)),
              ),
              const SizedBox(height: 12),
              const Divider(),
              _buildContributorSection(
                title: 'Effort Contributors',
                selectedIds: _effortContributorIds,
              ),
              _buildEffortPercentageFields(),
              const Divider(),
              _buildContributorSection(
                title: 'Marketing Contributors',
                selectedIds: _marketingContributorIds,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveProduct,
          child: Text(isEditing ? 'Update' : 'Save'),
        ),
      ],
    );
  }
}