import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  bool _isBikesTab = true;
  final currencyFormatter =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    // Listen to the specific inventory providers
    final bikesAsync = ref.watch(detailedBikesProvider);
    final accessoriesAsync = ref.watch(detailedAccessoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Inventory Management',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const Text('Track motorcycles and accessories stock',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddMotorcycleDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add Motorcycle',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
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

          // Tab Toggle
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleTab('Motorcycles', _isBikesTab,
                    () => setState(() => _isBikesTab = true)),
                _buildToggleTab('Accessories & Gear', !_isBikesTab,
                    () => setState(() => _isBikesTab = false)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Data Table with Async Handling
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: _isBikesTab
                  ? bikesAsync.when(
                      skipLoadingOnRefresh: true,
                      data: (bikes) =>
                          SingleChildScrollView(child: _buildBikesTable(bikes)),
                      loading: () => const Center(
                          child: CircularProgressIndicator(color: Colors.red)),
                      error: (e, _) => Center(
                          child: Text('Error: $e',
                              style: const TextStyle(color: Colors.white))),
                    )
                  : accessoriesAsync.when(
                      skipLoadingOnRefresh: true,
                      data: (acc) => SingleChildScrollView(
                          child: _buildAccessoriesTable(acc)),
                      loading: () => const Center(
                          child: CircularProgressIndicator(color: Colors.red)),
                      error: (e, _) => Center(
                          child: Text('Error: $e',
                              style: const TextStyle(color: Colors.white))),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildBikesTable(List<Map<String, dynamic>> bikes) {
    return DataTable(
      headingTextStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      columns: const [
        DataColumn(label: Text('VIN')),
        DataColumn(label: Text('Brand')),
        DataColumn(label: Text('Model')),
        DataColumn(label: Text('Color')),
        DataColumn(label: Text('Engine No.')),
        DataColumn(label: Text('Price')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')), // New Column
      ],
      rows: bikes.map((bike) {
        final model = bike['bike_models'];
        final status = bike['status'].toString().replaceAll('_', ' ');
        return DataRow(cells: [
          DataCell(Text(bike['vin_number'],
              style: const TextStyle(color: Colors.grey))),
          DataCell(Text(model['brand'],
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(model['model_name'])),
          DataCell(Text(bike['color'] ?? 'N/A')),
          DataCell(Text(bike['engine_number'],
              style: const TextStyle(color: Colors.grey))),
          DataCell(Text(currencyFormatter.format(model['base_price']))),
          DataCell(_buildStatusBadge(status)),
          DataCell(
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 18),
              onPressed: () => _showEditBikeDialog(bike),
            ),
          ),
        ]);
      }).toList(),
    );
  }

  Widget _buildAccessoriesTable(List<Map<String, dynamic>> accessories) {
    return DataTable(
      headingTextStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      columns: const [
        DataColumn(label: Text('SKU')),
        DataColumn(label: Text('Product')),
        DataColumn(label: Text('Variant')),
        DataColumn(label: Text('Stock')),
        DataColumn(label: Text('Price')),
        DataColumn(label: Text('Actions')), // New Column
      ],
      rows: accessories.map((acc) {
        final product = acc['products'];
        final stock = acc['stock_quantity'] as int;
        return DataRow(cells: [
          DataCell(
              Text(acc['sku'], style: const TextStyle(color: Colors.grey))),
          DataCell(Text(product['name'],
              style: const TextStyle(fontWeight: FontWeight.bold))),
          DataCell(Text(acc['variant_name'])),
          DataCell(Row(
            children: [
              Text('$stock'),
              if (stock <= 5 && stock > 0) ...[
                const SizedBox(width: 8),
                _buildBadge('Low Stock', Colors.orange),
              ] else if (stock == 0) ...[
                const SizedBox(width: 8),
                _buildBadge('Out of Stock', Colors.red),
              ]
            ],
          )),
          DataCell(Text(currencyFormatter.format(acc['price']))),
          DataCell(
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 18),
              onPressed: () => _showEditAccessoryDialog(acc),
            ),
          ),
        ]);
      }).toList(),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'in stock') color = Colors.green;
    if (status == 'sold') color = Colors.red;

    return _buildBadge(status.toUpperCase(), color,
        outlined: status == 'in stock');
  }

  Widget _buildBadge(String text, Color color, {bool outlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildToggleTab(String text, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF252525) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  // --- DIALOG LOGIC METHODS ---

  void _showEditAccessoryDialog(Map<String, dynamic> acc) {
    final sku = acc['sku'];
    final name = acc['products']['name'];
    final variant = acc['variant_name'];

    final priceController =
        TextEditingController(text: acc['price'].toString());
    final stockController =
        TextEditingController(text: acc['stock_quantity'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text('Edit $name', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(variant, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Price (\$)',
                  labelStyle: TextStyle(color: Colors.grey)),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  labelStyle: TextStyle(color: Colors.grey)),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () async {
              final newPrice = double.tryParse(priceController.text) ?? 0.0;
              final newStock = int.tryParse(stockController.text) ?? 0;

              await ref
                  .read(databaseProvider)
                  .updateAccessory(sku, newPrice, newStock);

              if (context.mounted) {
                ref.invalidate(detailedAccessoriesProvider);
                ref.invalidate(inventoryProvider); // Refresh POS too
                Navigator.pop(context);
              }
            },
            child: const Text('Save Changes',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditBikeDialog(Map<String, dynamic> bike) {
    final vin = bike['vin_number'];
    final modelName = bike['bike_models']['model_name'];
    String currentStatus = bike['status'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('Edit Status: $modelName',
              style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('VIN: $vin', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: currentStatus,
                dropdownColor: const Color(0xFF252525),
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: 'in_stock', child: Text('In Stock')),
                  DropdownMenuItem(value: 'sold', child: Text('Sold')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => currentStatus = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: () async {
                await ref
                    .read(databaseProvider)
                    .updateBikeStatus(vin, currentStatus);

                if (context.mounted) {
                  ref.invalidate(detailedBikesProvider);
                  ref.invalidate(inventoryProvider);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Changes',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      }),
    );
  }

  void _showAddMotorcycleDialog() {
    final vinController = TextEditingController();
    final engineController = TextEditingController();
    final colorController = TextEditingController();
    final modelIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Add New Motorcycle',
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: vinController,
                decoration: const InputDecoration(
                    labelText: 'VIN Number',
                    labelStyle: TextStyle(color: Colors.grey)),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: engineController,
                decoration: const InputDecoration(
                    labelText: 'Engine Number',
                    labelStyle: TextStyle(color: Colors.grey)),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(
                    labelText: 'Color',
                    labelStyle: TextStyle(color: Colors.grey)),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: modelIdController,
                decoration: const InputDecoration(
                    labelText: 'Model UUID',
                    helperText: 'Requires a valid UUID from bike_models',
                    helperStyle: TextStyle(color: Colors.grey),
                    labelStyle: TextStyle(color: Colors.grey)),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary),
            onPressed: () async {
              if (vinController.text.isEmpty || modelIdController.text.isEmpty)
                return;

              try {
                await ref.read(databaseProvider).addMotorcycle(
                      vin: vinController.text,
                      engineNo: engineController.text,
                      color: colorController.text,
                      modelId: modelIdController.text,
                    );

                if (context.mounted) {
                  ref.invalidate(detailedBikesProvider);
                  ref.invalidate(inventoryProvider);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Motorcycle added successfully!'),
                      backgroundColor: Colors.green));
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Add Motorcycle',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
