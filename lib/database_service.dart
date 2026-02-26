import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

// 1. Provide the DatabaseService to the rest of the app
final databaseProvider = Provider((ref) => DatabaseService());

// 2. Create a FutureProvider that automatically fetches the data when the POS loads
final inventoryProvider =
    FutureProvider<Map<String, List<Product>>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.fetchInventory();
});

class DatabaseService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, List<Product>>> fetchInventory() async {
    // Fetch 1: Motorcycles (Joining 'bikes' with 'bike_models')
    final bikesResponse = await _supabase
        .from('bikes')
        .select('vin_number, bike_models(brand, model_name, base_price)')
        .eq('status', 'in_stock'); // Only fetch bikes available to sell

    List<Product> fetchedBikes = bikesResponse.map((row) {
      final modelData = row['bike_models'];
      return Product(
        id: row['vin_number'], // VIN is the unique identifier
        name: modelData['brand'],
        subtitle: modelData['model_name'],
        price: (modelData['base_price'] as num).toDouble(),
        isBike: true,
      );
    }).toList();

    // Fetch 2: Accessories (Joining 'product_variants' with 'products')
    final accessoriesResponse = await _supabase
        .from('product_variants')
        .select('id, sku, variant_name, price, stock_quantity, products(name)')
        .gt('stock_quantity', 0); // Only fetch items with stock > 0

    List<Product> fetchedAccessories = accessoriesResponse.map((row) {
      final parentProduct = row['products'];
      return Product(
        id: row['id'], // Variant UUID is the unique identifier
        name: parentProduct['name'],
        subtitle: row['variant_name'],
        price: (row['price'] as num).toDouble(),
        isBike: false,
      );
    }).toList();

    return {
      'bikes': fetchedBikes,
      'accessories': fetchedAccessories,
    };
  }

  // Add this inside your DatabaseService class
  Future<void> checkout({
    required double subtotal,
    required double vatAmount,
    required double grandTotal,
    required String paymentType,
    required List<CartItem> cartItems,
  }) async {
    // 1. Format the cart items into the JSON structure our RPC expects
    final List<Map<String, dynamic>> itemsPayload = cartItems
        .map((item) => {
              'id': item.product.id,
              'is_bike': item.product.isBike,
              'price': item.product.price,
              'quantity': item.quantity,
            })
        .toList();

    // 2. Call the Supabase RPC function
    await _supabase.rpc('process_checkout', params: {
      'p_customer_id': null, // Leaving null for walk-in customers for now
      'p_subtotal': subtotal,
      'p_vat_amount': vatAmount,
      'p_grand_total': grandTotal,
      'p_payment_type': paymentType,
      'p_cart_items': itemsPayload,
    });
  }
}
