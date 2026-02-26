import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
// Note: If your CartItem class is in cart_provider.dart instead of models.dart,
// make sure to import 'cart_provider.dart' here as well.

// ==========================================
// 1. PROVIDERS
// ==========================================

// Provides the base DatabaseService to the app
final databaseProvider = Provider((ref) => DatabaseService());

// Provides the formatted UI-ready inventory for the POS Screen
final inventoryProvider =
    FutureProvider<Map<String, List<Product>>>((ref) async {
  final db = ref.read(databaseProvider);
  return await db.fetchInventory();
});

// Provides the raw detailed data for the Inventory Screen (Bikes)
final detailedBikesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(databaseProvider).fetchDetailedBikes();
});

// Provides the raw detailed data for the Inventory Screen (Accessories)
final detailedAccessoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(databaseProvider).fetchDetailedAccessories();
});

// ==========================================
// 2. DATABASE SERVICE CLASS
// ==========================================

class DatabaseService {
  final _supabase = Supabase.instance.client;

  // --- POS FETCH METHODS ---

  Future<Map<String, List<Product>>> fetchInventory() async {
    // 1. Fetch Bikes (Joining 'bikes' with 'bike_models')
    final bikesResponse = await _supabase
        .from('bikes')
        .select('vin_number, bike_models(brand, model_name, base_price)')
        .eq('status', 'in_stock');

    List<Product> fetchedBikes = bikesResponse.map((row) {
      final modelData = row['bike_models'];
      return Product(
        id: row['vin_number'],
        name: modelData['brand'],
        subtitle: modelData['model_name'],
        price: (modelData['base_price'] as num).toDouble(),
        isBike: true,
        stock: 1, // A specific VIN is a single physical unit
      );
    }).toList();

    // 2. Fetch Accessories (Joining 'product_variants' with 'products')
    final accessoriesResponse = await _supabase
        .from('product_variants')
        .select('id, sku, variant_name, price, stock_quantity, products(name)')
        .gt('stock_quantity', 0); // Only fetch items with stock

    List<Product> fetchedAccessories = accessoriesResponse.map((row) {
      final parentProduct = row['products'];
      return Product(
        id: row['id'],
        name: parentProduct['name'],
        subtitle: row['variant_name'],
        price: (row['price'] as num).toDouble(),
        isBike: false,
        stock: row['stock_quantity'] as int, // Pull actual database stock
      );
    }).toList();

    return {
      'bikes': fetchedBikes,
      'accessories': fetchedAccessories,
    };
  }

  // --- CHECKOUT RPC CALL ---

  Future<void> checkout({
    required double subtotal,
    required double vatAmount,
    required double grandTotal,
    required String paymentType,
    required List<CartItem> cartItems,
  }) async {
    // Format the cart items into the JSON array our PostgreSQL RPC expects
    final List<Map<String, dynamic>> itemsPayload = cartItems
        .map((item) => {
              'id': item.product.id,
              'is_bike': item.product.isBike,
              'price': item.product.price,
              'quantity': item.quantity,
            })
        .toList();

    // Call the Supabase RPC function
    await _supabase.rpc('process_checkout', params: {
      'p_customer_id': null,
      'p_subtotal': subtotal,
      'p_vat_amount': vatAmount,
      'p_grand_total': grandTotal,
      'p_payment_type': paymentType,
      'p_cart_items': itemsPayload,
    });
  }

  // --- INVENTORY MANAGEMENT FETCH METHODS ---

  Future<List<Map<String, dynamic>>> fetchDetailedBikes() async {
    final response = await _supabase
        .from('bikes')
        .select(
            'vin_number, engine_number, color, status, warehouse_location, bike_models(brand, model_name, base_price)')
        .order('vin_number', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchDetailedAccessories() async {
    final response = await _supabase
        .from('product_variants')
        .select('sku, variant_name, price, stock_quantity, products(name)')
        .order('sku', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // --- INVENTORY MANAGEMENT WRITE METHODS ---

  Future<void> updateAccessory(String sku, double price, int stock) async {
    await _supabase
        .from('product_variants')
        .update({'price': price, 'stock_quantity': stock}).eq('sku', sku);
  }

  Future<void> updateBikeStatus(String vin, String newStatus) async {
    await _supabase
        .from('bikes')
        .update({'status': newStatus}).eq('vin_number', vin);
  }

  Future<void> addMotorcycle({
    required String vin,
    required String engineNo,
    required String modelId,
    required String color,
  }) async {
    await _supabase.from('bikes').insert({
      'vin_number': vin,
      'engine_number': engineNo,
      'model_id': modelId,
      'color': color,
      'status': 'in_stock',
    });
  }
}
