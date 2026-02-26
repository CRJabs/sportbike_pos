import 'package:flutter/material.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _isBikesTab = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Inventory Management',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const Text('Track motorcycles and accessories stock',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),

          // Tabs
          Container(
            decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleTab('Motorcycles (12)', _isBikesTab,
                    () => setState(() => _isBikesTab = true)),
                _buildToggleTab('Accessories & Gear (18)', !_isBikesTab,
                    () => setState(() => _isBikesTab = false)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Data Table Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: SingleChildScrollView(
                child:
                    _isBikesTab ? _buildBikesTable() : _buildAccessoriesTable(),
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildBikesTable() {
    return DataTable(
      headingTextStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      dividerThickness: 0.5,
      columns: const [
        DataColumn(label: Text('VIN')),
        DataColumn(label: Text('Brand')),
        DataColumn(label: Text('Model')),
        DataColumn(label: Text('Color')),
        DataColumn(label: Text('Engine No.')),
        DataColumn(label: Text('Price')),
        DataColumn(label: Text('Status')),
      ],
      rows: [
        _buildBikeRow(
            'ZDMV4CES1NB000101',
            'Ducati',
            'Panigale V4',
            'Ducati Red',
            'DUC-V4-20261001',
            '\$28,995',
            'In Showroom',
            Colors.green),
        _buildBikeRow(
            'JKAZX10R1NA000202',
            'Kawasaki',
            'Ninja ZX-10R',
            'Metallic Black',
            'KAW-ZX10-20261002',
            '\$17,599',
            'Reserved',
            Colors.orange),
        _buildBikeRow('JYARN83Y1NA000402', 'Yamaha', 'YZF-R1', 'Tech Black',
            'YAM-R1-20261002', '\$17,899', 'Sold', Colors.grey),
      ],
    );
  }

  DataRow _buildBikeRow(String vin, String brand, String model, String color,
      String engine, String price, String status, Color statusColor) {
    return DataRow(cells: [
      DataCell(Text(vin, style: const TextStyle(color: Colors.grey))),
      DataCell(
          Text(brand, style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(model)),
      DataCell(Text(color)),
      DataCell(Text(engine, style: const TextStyle(color: Colors.grey))),
      DataCell(
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(
          _buildBadge(status, statusColor, outlined: status == 'In Showroom')),
    ]);
  }

  Widget _buildAccessoriesTable() {
    return DataTable(
      headingTextStyle: const TextStyle(color: Colors.grey, fontSize: 12),
      dataTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      dividerThickness: 0.5,
      columns: const [
        DataColumn(label: Text('SKU')),
        DataColumn(label: Text('Product')),
        DataColumn(label: Text('Variant')),
        DataColumn(label: Text('Stock')),
        DataColumn(label: Text('Price')),
      ],
      rows: [
        _buildAccRow('SCH-M-BLK', 'Spyder Corsa Helmet', 'Size M / Black', '12',
            '\$450', null),
        _buildAccRow('SCH-L-RED', 'Spyder Corsa Helmet', 'Size L / Red', '3',
            '\$475', 'Low Stock'),
        _buildAccRow('CTS-UNI-RED', 'Carbon Fiber Tank Sliders',
            'Universal / Red', '0', '\$115', 'Out of Stock'),
      ],
    );
  }

  DataRow _buildAccRow(String sku, String product, String variant, String stock,
      String price, String? status) {
    return DataRow(cells: [
      DataCell(Text(sku, style: const TextStyle(color: Colors.grey))),
      DataCell(
          Text(product, style: const TextStyle(fontWeight: FontWeight.bold))),
      DataCell(Text(variant)),
      DataCell(Row(
        children: [
          Text(stock),
          if (status != null) ...[
            const SizedBox(width: 8),
            _buildBadge(status,
                status == 'Low Stock' ? Colors.redAccent : Colors.red[900]!,
                outlined: false),
          ]
        ],
      )),
      DataCell(
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold))),
    ]);
  }

  Widget _buildBadge(String text, Color color, {bool outlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withOpacity(0.8),
        border: outlined ? Border.all(color: color) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: TextStyle(
              color: outlined ? color : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}
