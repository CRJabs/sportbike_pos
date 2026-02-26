import 'package:flutter/material.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  bool _isBikesTab = false; // Toggle for Bikes vs Accessories

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Side: Inventory Catalog
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tabs & Search
                Row(
                  children: [
                    _buildTabButton('Bikes', Icons.motorcycle, _isBikesTab,
                        () => setState(() => _isBikesTab = true)),
                    const SizedBox(width: 12),
                    _buildTabButton(
                        'Accessories',
                        Icons.shield_outlined,
                        !_isBikesTab,
                        () => setState(() => _isBikesTab = false)),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Search ${_isBikesTab ? 'bikes' : 'accessories'}...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),

                // Grid Content
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 8,
                    itemBuilder: (context, index) => _buildProductCard(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Side: Cart
        Container(
          width: 380,
          color: const Color(0xFF141414),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Order',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Text('4 items',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),

              // Cart Items List
              Expanded(
                child: ListView(
                  children: [
                    _buildCartItem(
                        'Spyder Corsa Helmet', 'Size M / Black', '\$450.00'),
                    _buildCartItem(
                        'Spyder Corsa Helmet', 'Size L / Red', '\$475.00'),
                    _buildCartItem(
                        'ProGrip Racing Gloves', 'Size S / Black', '\$95.00'),
                    _buildCartItem(
                        'Alpine Racing Jacket', 'Size XL / Red', '\$395.00'),
                  ],
                ),
              ),

              // Totals & Checkout
              const Divider(color: Colors.white12),
              const SizedBox(height: 16),
              _buildSummaryRow('Subtotal', '\$1,415.00'),
              const SizedBox(height: 8),
              _buildSummaryRow('VAT (11%)', '\$155.65'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount %',
                      style: TextStyle(color: Colors.grey)),
                  Container(
                    width: 60,
                    height: 30,
                    decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(4)),
                    alignment: Alignment.center,
                    child:
                        const Text('0', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('\$1,570.65',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.credit_card, color: Colors.white),
                  label: const Text('Checkout',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(
      String text, IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Placeholder
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF252525),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Icon(
                  _isBikesTab ? Icons.motorcycle : Icons.shield_outlined,
                  color: Colors.grey[600],
                  size: 40),
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isBikesTab ? 'Ducati' : 'Spyder Corsa Helmet',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(_isBikesTab ? 'Panigale V4' : 'Size M / Black',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_isBikesTab ? '\$28,995' : '\$450',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold)),
                    if (!_isBikesTab)
                      const Text('8 left',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(String title, String subtitle, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(price,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.remove, color: Colors.grey, size: 16),
              const SizedBox(width: 8),
              const Text('1', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              const Icon(Icons.add, color: Colors.grey, size: 16),
              const SizedBox(width: 16),
              Icon(Icons.close,
                  color: Theme.of(context).colorScheme.primary, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
