import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isBikesTab = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _isBikesTab = _tabController.index == 0;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(symbol: '₱', decimalDigits: 2);
    final bikesAsync = ref.watch(detailedBikesProvider);
    final accessoriesAsync = ref.watch(detailedAccessoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Inventory Management',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text('Manage motorcycles and accessories stock',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _isBikesTab
                    ? _showAddMotorcycleDialog()
                    : _showAddAccessoryDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  _isBikesTab ? 'Add Motorcycle' : 'Add Accessory',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              labelColor: Colors.white,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Motorcycles'),
                Tab(text: 'Accessories & Gear'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  // 1. MOTORCYCLES TAB
                  bikesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.red)),
                    error: (e, _) => Center(
                        child: Text('Error: $e',
                            style: const TextStyle(color: Colors.red))),
                    data: (bikes) {
                      if (bikes.isEmpty)
                        return const Center(
                            child: Text('No motorcycles in inventory.',
                                style: TextStyle(color: Colors.grey)));
                      return SingleChildScrollView(
                        child: DataTable(
                          headingTextStyle:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                          dataTextStyle: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          columns: const [
                            DataColumn(label: Text('VIN')),
                            DataColumn(label: Text('Brand')),
                            DataColumn(label: Text('Model & Color')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: bikes.map((bike) {
                            return DataRow(cells: [
                              DataCell(Text(
                                  bike['vin_number']
                                          .toString()
                                          .substring(0, 8) +
                                      '...',
                                  style: const TextStyle(color: Colors.grey))),
                              DataCell(Text(bike['brand'] ?? 'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                              DataCell(Text(
                                  '${bike['model_name']} - ${bike['color']}')),
                              DataCell(Text(currencyFormatter
                                  .format(bike['base_price']))),
                              DataCell(_buildStatusBadge(bike['status'])),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.grey, size: 20),
                                  onPressed: () => _showEditBikeDialog(bike),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      );
                    },
                  ),

                  // 2. ACCESSORIES TAB
                  accessoriesAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.red)),
                    error: (e, _) => Center(
                        child: Text('Error: $e',
                            style: const TextStyle(color: Colors.red))),
                    data: (accessories) {
                      if (accessories.isEmpty)
                        return const Center(
                            child: Text('No accessories in inventory.',
                                style: TextStyle(color: Colors.grey)));
                      return SingleChildScrollView(
                        child: DataTable(
                          headingTextStyle:
                              const TextStyle(color: Colors.grey, fontSize: 12),
                          dataTextStyle: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          columns: const [
                            DataColumn(label: Text('SKU')),
                            DataColumn(label: Text('Product')),
                            DataColumn(label: Text('Variant')),
                            DataColumn(label: Text('Price')),
                            DataColumn(label: Text('Stock')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: accessories.map((acc) {
                            return DataRow(cells: [
                              DataCell(Text(acc['sku'],
                                  style: const TextStyle(color: Colors.grey))),
                              DataCell(Text(acc['product_name'] ?? 'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                              DataCell(Text(acc['variant_name'])),
                              DataCell(
                                  Text(currencyFormatter.format(acc['price']))),
                              DataCell(Text(acc['stock_quantity'].toString())),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.grey, size: 20),
                                  onPressed: () =>
                                      _showEditAccessoryDialog(acc),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'in_stock' ? Colors.green : Colors.red;
    String text = status.replaceAll('_', ' ').toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showAddMotorcycleDialog() {
    final vinController = TextEditingController();
    final engineController = TextEditingController();
    final colorController = TextEditingController();
    final modelIdController = TextEditingController();

    Uint8List? selectedImageBytes;
    String? selectedImageName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Add New Motorcycle',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      final bytes = await pickedFile.readAsBytes();
                      setState(() {
                        selectedImageBytes = bytes;
                        selectedImageName = pickedFile.name;
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10)),
                    clipBehavior: Clip.antiAlias,
                    child: selectedImageBytes != null
                        ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Icon(Icons.add_photo_alternate,
                                    color: Colors.grey, size: 40),
                                SizedBox(height: 8),
                                Text('Upload Specific Unit Image',
                                    style: TextStyle(color: Colors.grey))
                              ]),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                    controller: vinController,
                    decoration: const InputDecoration(
                        labelText: 'VIN Number',
                        labelStyle: TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)),
                TextField(
                    controller: engineController,
                    decoration: const InputDecoration(
                        labelText: 'Engine Number',
                        labelStyle: TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)),
                TextField(
                    controller: colorController,
                    decoration: const InputDecoration(
                        labelText: 'Color',
                        labelStyle: TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)),
                TextField(
                    controller: modelIdController,
                    decoration: const InputDecoration(
                        labelText: 'Model UUID',
                        helperText: 'Requires a valid UUID from bike_models',
                        helperStyle: TextStyle(color: Colors.grey),
                        labelStyle: TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: isUploading
                  ? null
                  : () async {
                      if (vinController.text.isEmpty ||
                          modelIdController.text.isEmpty) return;
                      setState(() => isUploading = true);
                      String? finalImageUrl;

                      try {
                        if (selectedImageBytes != null &&
                            selectedImageName != null) {
                          finalImageUrl = await ref
                              .read(databaseProvider)
                              .uploadImage(
                                  selectedImageName!, selectedImageBytes!);
                        }

                        await ref.read(databaseProvider).addMotorcycle(
                            vin: vinController.text,
                            engineNo: engineController.text,
                            color: colorController.text,
                            modelId: modelIdController.text,
                            imageUrl: finalImageUrl);
                        if (!context.mounted) return;
                        ref.invalidate(detailedBikesProvider);
                        ref.invalidate(inventoryProvider);
                        Navigator.pop(context);
                      } catch (e) {
                        setState(() => isUploading = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red));
                      }
                    },
              child: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Add Motorcycle',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  void _showEditBikeDialog(Map<String, dynamic> bike) {
    final vin = bike['vin_number'];
    final modelId = bike['model_id'];
    final brand = bike['brand'] ?? 'Unknown';
    final modelName = bike['model_name'] ?? 'Model';
    final color = bike['color'];
    final currentImageUrl = bike['image_url'];

    final priceController =
        TextEditingController(text: bike['base_price'].toString());
    String currentStatus = bike['status'].toString();

    Uint8List? selectedImageBytes;
    String? selectedImageName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('Edit $brand $modelName\n($color)',
              style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VIN: $vin', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      final bytes = await pickedFile.readAsBytes();
                      setState(() {
                        selectedImageBytes = bytes;
                        selectedImageName = pickedFile.name;
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10)),
                    clipBehavior: Clip.antiAlias,
                    child: selectedImageBytes != null
                        ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                        : currentImageUrl != null
                            ? Image.network(currentImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image_not_supported,
                                              color: Colors.grey, size: 40),
                                          SizedBox(height: 8),
                                          Text('Offline: Preview Unavailable',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 10))
                                        ]))
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Icon(Icons.cloud_upload,
                                        color: Colors.grey, size: 40),
                                    SizedBox(height: 8),
                                    Text('Click to upload image',
                                        style: TextStyle(color: Colors.grey))
                                  ]),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                    controller: priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Base Price (₱)',
                        labelStyle: TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: currentStatus,
                  dropdownColor: const Color(0xFF252525),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white10)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  items: const [
                    DropdownMenuItem(
                        value: 'in_stock', child: Text('In Stock')),
                    DropdownMenuItem(value: 'sold', child: Text('Sold')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => currentStatus = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: isUploading
                  ? null
                  : () async {
                      setState(() => isUploading = true);
                      final newPrice =
                          double.tryParse(priceController.text) ?? 0.0;
                      String? finalImageUrl;

                      try {
                        if (selectedImageBytes != null &&
                            selectedImageName != null) {
                          finalImageUrl = await ref
                              .read(databaseProvider)
                              .uploadImage(
                                  selectedImageName!, selectedImageBytes!);
                        }

                        await ref.read(databaseProvider).updateMotorcycle(
                            vin: vin,
                            modelId: modelId,
                            status: currentStatus,
                            price: newPrice,
                            imageUrl: finalImageUrl);
                        if (!context.mounted) return;
                        ref.invalidate(detailedBikesProvider);
                        ref.invalidate(inventoryProvider);
                        Navigator.pop(context);
                      } catch (e) {
                        setState(() => isUploading = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error saving: $e'),
                            backgroundColor: Colors.red));
                      }
                    },
              child: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  void _showAddAccessoryDialog() {
    final skuController = TextEditingController();
    final productIdController = TextEditingController();
    final variantController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    Uint8List? selectedImageBytes;
    String? selectedImageName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Add New Accessory/Gear',
              style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      final bytes = await pickedFile.readAsBytes();
                      setState(() {
                        selectedImageBytes = bytes;
                        selectedImageName = pickedFile.name;
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10)),
                    clipBehavior: Clip.antiAlias,
                    child: selectedImageBytes != null
                        ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Icon(Icons.add_photo_alternate,
                                    color: Colors.grey, size: 40),
                                SizedBox(height: 8),
                                Text('Upload Product Image',
                                    style: TextStyle(color: Colors.grey))
                              ]),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                    controller: skuController,
                    decoration: const InputDecoration(
                        labelText: 'SKU (e.g., SH-RF1400-WHT-M)',
                        labelStyle: TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)),
                TextField(
                    controller: productIdController,
                    decoration: const InputDecoration(
                        labelText: 'Product UUID',
                        helperText: 'Requires a valid UUID from products table',
                        helperStyle: TextStyle(color: Colors.grey),
                        labelStyle: TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)),
                TextField(
                    controller: variantController,
                    decoration: const InputDecoration(
                        labelText: 'Variant Name',
                        labelStyle: TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)),
                TextField(
                    controller: priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Price (₱)',
                        labelStyle: TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)),
                TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Initial Stock Quantity',
                        labelStyle: TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: isUploading
                  ? null
                  : () async {
                      if (skuController.text.isEmpty ||
                          productIdController.text.isEmpty) return;
                      setState(() => isUploading = true);
                      final newPrice =
                          double.tryParse(priceController.text) ?? 0.0;
                      final newStock = int.tryParse(stockController.text) ?? 0;
                      String? finalImageUrl;

                      try {
                        if (selectedImageBytes != null &&
                            selectedImageName != null) {
                          finalImageUrl = await ref
                              .read(databaseProvider)
                              .uploadImage(
                                  selectedImageName!, selectedImageBytes!);
                        }

                        await ref.read(databaseProvider).addAccessory(
                            sku: skuController.text,
                            productId: productIdController.text,
                            variantName: variantController.text,
                            price: newPrice,
                            stock: newStock,
                            imageUrl: finalImageUrl);

                        if (!context.mounted) return;
                        ref.invalidate(detailedAccessoriesProvider);
                        ref.invalidate(inventoryProvider);
                        Navigator.pop(context);
                      } catch (e) {
                        setState(() => isUploading = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red));
                      }
                    },
              child: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Add Accessory',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  void _showEditAccessoryDialog(Map<String, dynamic> accessory) {
    final sku = accessory['sku'];
    final name = accessory['product_name'] ?? 'Accessory';
    final variantName = accessory['variant_name'];
    final currentImageUrl = accessory['image_url'];

    final priceController =
        TextEditingController(text: accessory['price'].toString());
    final stockController =
        TextEditingController(text: accessory['stock_quantity'].toString());

    Uint8List? selectedImageBytes;
    String? selectedImageName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title:
              Text('Edit $name', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(variantName, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      final bytes = await pickedFile.readAsBytes();
                      setState(() {
                        selectedImageBytes = bytes;
                        selectedImageName = pickedFile.name;
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10)),
                    clipBehavior: Clip.antiAlias,
                    child: selectedImageBytes != null
                        ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                        : currentImageUrl != null
                            ? Image.network(currentImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image_not_supported,
                                              color: Colors.grey, size: 40),
                                          SizedBox(height: 8),
                                          Text('Offline: Preview Unavailable',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 10))
                                        ]))
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Icon(Icons.cloud_upload,
                                        color: Colors.grey, size: 40),
                                    SizedBox(height: 8),
                                    Text('Click to upload image',
                                        style: TextStyle(color: Colors.grey))
                                  ]),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                    controller: priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Price (₱)',
                        labelStyle: TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Stock Quantity',
                        labelStyle: TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: isUploading
                  ? null
                  : () async {
                      setState(() => isUploading = true);
                      final newPrice =
                          double.tryParse(priceController.text) ?? 0.0;
                      final newStock = int.tryParse(stockController.text) ?? 0;
                      String? finalImageUrl;

                      try {
                        if (selectedImageBytes != null &&
                            selectedImageName != null) {
                          finalImageUrl = await ref
                              .read(databaseProvider)
                              .uploadImage(
                                  selectedImageName!, selectedImageBytes!);
                        }

                        await ref.read(databaseProvider).updateAccessory(
                            sku: sku,
                            price: newPrice,
                            stock: newStock,
                            imageUrl: finalImageUrl);

                        if (!context.mounted) return;
                        ref.invalidate(detailedAccessoriesProvider);
                        ref.invalidate(inventoryProvider);
                        Navigator.pop(context);
                      } catch (e) {
                        setState(() => isUploading = false);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error saving: $e'),
                            backgroundColor: Colors.red));
                      }
                    },
              child: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }
}
