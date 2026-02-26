import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

// The Notifier that manages the List of CartItems
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(Product product) {
    // Check if the item is already in the cart
    final existingIndex =
        state.indexWhere((item) => item.product.id == product.id);

    if (existingIndex != -1) {
      // Increase quantity if it exists
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i]
      ];
    } else {
      // Add new item to cart
      state = [...state, CartItem(product: product)];
    }
  }

  void removeItem(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(String productId, int delta) {
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(
              quantity: (item.quantity + delta)
                  .clamp(1, 99)) // Prevents going below 1
        else
          item
    ];
  }

  void clearCart() {
    state = [];
  }
}

// The Providers that the UI will listen to
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

// Computed providers for instant math
final cartSubtotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(
      0, (total, item) => total + (item.product.price * item.quantity));
});

final cartVatProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  return subtotal * 0.11; // 11% VAT based on your design
});

final cartTotalProvider = Provider<double>((ref) {
  final subtotal = ref.watch(cartSubtotalProvider);
  final vat = ref.watch(cartVatProvider);
  return subtotal + vat;
});
