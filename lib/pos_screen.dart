import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';
import 'models.dart';
import 'checkout_dialog.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>(
    (ref) => CartNotifier());

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(Product product) {
    if (product.isBike) {
      if (state.any((item) => item.product.id == product.id)) return;
      state = [...state, CartItem(product: product, quantity: 1)];
    } else {
      final existingIndex =
          state.indexWhere((item) => item.product.id == product.id);
      if (existingIndex >= 0) {
        final newState = [...state];
        if (newState[existingIndex].quantity < product.stock) {
          newState[existingIndex] = CartItem(
              product: product, quantity: newState[existingIndex].quantity + 1);
          state = newState;
        }
      } else {
        if (product.stock > 0) {
          state = [...state, CartItem(product: product, quantity: 1)];
        }
      }
    }
  }

  void decreaseQuantity(String productId) {
    final existingIndex =
        state.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      final currentItem = state[existingIndex];
      if (currentItem.quantity > 1) {
        final newState = [...state];
        newState[existingIndex] = CartItem(
            product: currentItem.product, quantity: currentItem.quantity - 1);
        state = newState;
      } else {
        removeFromCart(productId);
      }
    }
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clearCart() {
    state = [];
  }
}

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final cart = ref.watch(cartProvider);
    final currencyFormatter =
        NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    double cartTotal = 0;
    for (var item in cart) {
      cartTotal += item.product.price * item.quantity;
    }

    return Row(
      children: [
        // --- INVENTORY GRID (LEFT SIDE) ---
        Expanded(
          flex: 7,
          child: Container(
            color: const Color(0xFF0F0F0F),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Point of Sale',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search bike models or gear',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF1A1A1A),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8)),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        labelColor: Colors.white,
                        labelStyle:
                            const TextStyle(fontWeight: FontWeight.bold),
                        unselectedLabelColor: Colors.grey,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        tabs: const [
                          Tab(text: 'Motorcycles'),
                          Tab(text: 'Accessories & Gear'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: inventoryAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.red)),
                    error: (e, _) => Center(
                        child: Text('Error: $e',
                            style: const TextStyle(color: Colors.red))),
                    data: (products) {
                      final isBikesTab = _tabController.index == 0;
                      final filteredProducts = products.where((p) {
                        final matchesTab = p.isBike == isBikesTab;
                        final matchesSearch = p.name
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            p.subtitle
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase()) ||
                            p.id
                                .toLowerCase()
                                .contains(_searchQuery.toLowerCase());
                        return matchesTab && matchesSearch;
                      }).toList();

                      if (filteredProducts.isEmpty) {
                        return const Center(
                            child: Text('No items found matching criteria.',
                                style: TextStyle(color: Colors.grey)));
                      }
                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final inCart =
                              cart.any((item) => item.product.id == product.id);

                          return InkWell(
                            onTap: inCart && product.isBike
                                ? null
                                : () => ref
                                    .read(cartProvider.notifier)
                                    .addToCart(product),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: inCart
                                        ? Colors.redAccent
                                        : Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF252525),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(8))),
                                      child: product.imageUrl != null
                                          ? Image.network(
                                              product.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Icon(
                                                      product.isBike
                                                          ? Icons.two_wheeler
                                                          : Icons
                                                              .sports_motorsports,
                                                      color: Colors.grey,
                                                      size: 40),
                                            )
                                          : Icon(
                                              product.isBike
                                                  ? Icons.two_wheeler
                                                  : Icons.sports_motorsports,
                                              color: Colors.grey,
                                              size: 40),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(product.name,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        Text(product.subtitle,
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                                currencyFormatter
                                                    .format(product.price),
                                                style: const TextStyle(
                                                    color: Colors.redAccent,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            if (!product.isBike)
                                              Text('Stock: ${product.stock}',
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 10)),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- CART SIDEBAR (RIGHT SIDE) ---
        Expanded(
          flex: 3,
          child: Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Order',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 16),
                Expanded(
                  child: cart.isEmpty
                      ? const Center(
                          child: Text('Cart is empty',
                              style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: cart.length,
                          itemBuilder: (context, index) {
                            final item = cart[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.product.name,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                            currencyFormatter
                                                .format(item.product.price),
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (!item.product.isBike) ...[
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.grey,
                                              size: 20),
                                          onPressed: () => ref
                                              .read(cartProvider.notifier)
                                              .decreaseQuantity(
                                                  item.product.id),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                        ),
                                        Text('${item.quantity}',
                                            style: const TextStyle(
                                                color: Colors.white)),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline,
                                              color: Colors.grey,
                                              size: 20),
                                          onPressed: item.quantity <
                                                  item.product.stock
                                              ? () => ref
                                                  .read(cartProvider.notifier)
                                                  .addToCart(item.product)
                                              : null,
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                        ),
                                      ],
                                      if (item.product.isBike)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16.0),
                                          child: Text('1',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.redAccent, size: 20),
                                        onPressed: () => ref
                                            .read(cartProvider.notifier)
                                            .removeFromCart(item.product.id),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.only(left: 4),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const Divider(color: Colors.white10, height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text(currencyFormatter.format(cartTotal),
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: cart.isEmpty
                        ? null
                        : () async {
                            final success = await showDialog<bool>(
                              context: context,
                              builder: (context) => CheckoutDialog(items: cart),
                            );

                            if (success == true) {
                              ref.read(cartProvider.notifier).clearCart();
                            }
                          },
                    child: const Text('Charge Customer',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
