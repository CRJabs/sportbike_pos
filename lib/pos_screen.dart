import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'cart_provider.dart';
import 'database_service.dart';
import 'checkout_dialog.dart';

// 1. Create a simple provider to hold the search text
final searchQueryProvider = StateProvider<String>((ref) => '');

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  bool _isBikesTab = true;

  // Formatter for currency
  final currencyFormatter =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  // 2. Add a controller to manage the text field visually
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController
        .dispose(); // Always clean up controllers to prevent memory leaks
    super.dispose();
  }

  // 3. Helper method to handle switching tabs and clearing the search
  void _switchTab(bool isBikes) {
    setState(() => _isBikesTab = isBikes);
    _searchController.clear(); // Empty the text field visually
    ref.read(searchQueryProvider.notifier).state = ''; // Reset the search state
  }

  @override
  Widget build(BuildContext context) {
    // Watch the Cart logic
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final vat = ref.watch(cartVatProvider);
    final total = ref.watch(cartTotalProvider);

    // Watch the LIVE Database Inventory
    final inventoryState = ref.watch(inventoryProvider);

    // Watch what the user is typing in the search bar
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

    return inventoryState.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.red)),
      error: (error, stack) => Center(
          child: Text('Error loading database: $error',
              style: const TextStyle(color: Colors.white))),
      data: (inventoryMap) {
        // Grab the base list from Supabase
        final baseProducts =
            _isBikesTab ? inventoryMap['bikes']! : inventoryMap['accessories']!;

        // 4. Filter the list based on the search query
        final activeProducts = baseProducts.where((product) {
          final matchesName = product.name.toLowerCase().contains(searchQuery);
          final matchesSubtitle =
              product.subtitle.toLowerCase().contains(searchQuery);
          return matchesName ||
              matchesSubtitle; // Will show up if you search "Ducati" OR "Panigale"
        }).toList();

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
                    Row(
                      children: [
                        _buildTabButton('Bikes', Icons.motorcycle, _isBikesTab,
                            () => _switchTab(true)),
                        const SizedBox(width: 12),
                        _buildTabButton('Accessories', Icons.shield_outlined,
                            !_isBikesTab, () => _switchTab(false)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 5. Connect the TextField to the Controller and Provider
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        // Update Riverpod whenever a key is pressed
                        ref.read(searchQueryProvider.notifier).state = value;
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Search ${_isBikesTab ? 'bikes' : 'accessories'}...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(searchQueryProvider.notifier).state =
                                      '';
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFF1A1A1A),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dynamic Product Grid
                    Expanded(
                      child: activeProducts.isEmpty
                          ? Center(
                              child: Text(
                                'No ${_isBikesTab ? 'bikes' : 'accessories'} found matching "$searchQuery"',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: activeProducts.length,
                              itemBuilder: (context, index) {
                                final product = activeProducts[index];
                                return ProductCard(
                                    product:
                                        product); // Replace the old _buildProductCard call with this
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Side: Cart (Remains exactly the same)
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
                  Text('${cartItems.length} items',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: cartItems.isEmpty
                        ? const Center(
                            child: Text("Cart is empty",
                                style: TextStyle(color: Colors.grey)))
                        : ListView.builder(
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) =>
                                _buildCartItem(cartItems[index]),
                          ),
                  ),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                      'Subtotal', currencyFormatter.format(subtotal)),
                  const SizedBox(height: 8),
                  _buildSummaryRow('VAT (11%)', currencyFormatter.format(vat)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Grand Total',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text(currencyFormatter.format(total),
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
                      onPressed: cartItems.isEmpty
                          ? null
                          : () async {
                              // 1. Show the checkout dialog and wait for it to close
                              final bool? success = await showDialog<bool>(
                                context: context,
                                barrierDismissible:
                                    false, // Force them to click cancel or pay
                                builder: (BuildContext context) =>
                                    const CheckoutDialog(),
                              );

                              // 2. If it returns true, show the success message
                              if (success == true && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Payment Successful! Receipt generated.'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.credit_card, color: Colors.white),
                      label: const Text('Checkout',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        disabledBackgroundColor: Colors.grey[800],
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
      },
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

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        ref.read(cartProvider.notifier).addItem(product);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF252525),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Icon(
                    product.isBike ? Icons.motorcycle : Icons.shield_outlined,
                    color: Colors.grey[600],
                    size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(product.subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(currencyFormatter.format(product.price),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
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
                Text(item.product.name,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(item.product.subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                    currencyFormatter
                        .format(item.product.price * item.quantity),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.grey, size: 16),
                onPressed: () => ref
                    .read(cartProvider.notifier)
                    .updateQuantity(item.product.id, -1),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              Text('${item.quantity}',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              IconButton(
                // Visual Feedback: If the quantity in cart >= stock in DB, fade the icon
                icon: Icon(
                  Icons.add,
                  size: 16,
                  color: item.quantity >= item.product.stock
                      ? Colors.white24 // Faded red/white when disabled
                      : Colors.grey, // Normal color
                ),
                // Logical Feedback: If quantity >= stock, setting onPressed to null
                // automatically disables the button in Flutter.
                onPressed: item.quantity >= item.product.stock
                    ? null
                    : () => ref
                        .read(cartProvider.notifier)
                        .updateQuantity(item.product.id, 1),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(Icons.close,
                    color: Theme.of(context).colorScheme.primary, size: 16),
                onPressed: () =>
                    ref.read(cartProvider.notifier).removeItem(item.product.id),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
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

// Paste this at the bottom of pos_screen.dart

class ProductCard extends ConsumerStatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _isHovered = false;
  final currencyFormatter =
      NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    // 1. MouseRegion handles the hover detection and changes the cursor
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click, // Changes cursor to the pointing hand

      // 2. GestureDetector handles the actual tap to add to cart
      child: GestureDetector(
        onTap: () {
          ref.read(cartProvider.notifier).addItem(widget.product);
        },

        // 3. AnimatedContainer provides a smooth fade-in for the glow effect
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              // Switch border color to primary red when hovered
              color: _isHovered
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white10,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    // The "Glow" effect
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.25),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF252525),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(7)),
                  ),
                  // If we have an image URL, show it. Otherwise, show the icon.
                  child: widget.product.imageUrl != null &&
                          widget.product.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(7)),
                          child: Image.network(
                            widget.product.imageUrl!,
                            fit: BoxFit
                                .cover, // Ensures the photo fills the box perfectly
                            // Fallback if the URL is broken
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallbackIcon(),
                          ),
                        )
                      : _buildFallbackIcon(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.product.subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormatter.format(widget.product.price),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold),
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

  // Helper method to draw the glowing icon if no image is available
  Widget _buildFallbackIcon() {
    return AnimatedTheme(
      data: ThemeData(
        iconTheme: IconThemeData(
          color: _isHovered
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[600],
        ),
      ),
      child: Icon(
        widget.product.isBike ? Icons.motorcycle : Icons.shield_outlined,
        size: 40,
      ),
    );
  }
}
