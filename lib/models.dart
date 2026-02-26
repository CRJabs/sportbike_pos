class Product {
  final String id;
  final String name;
  final String subtitle; // e.g., "Panigale V4" or "Size M / Black"
  final double price;
  final bool isBike;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    this.isBike = false,
    this.stock = 0,
  });
}

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, this.quantity = 1});

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}
