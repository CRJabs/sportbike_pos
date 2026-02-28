import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'dart:typed_data';
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
    // 1. Fetch Bikes
    final bikesResponse = await _supabase
        .from('bikes')
        // ADD image_url to the select query below:
        .select(
            'vin_number, bike_models(brand, model_name, base_price, image_url)')
        .eq('status', 'in_stock');

    List<Product> fetchedBikes = bikesResponse.map((row) {
      final modelData = row['bike_models'];
      return Product(
        id: row['vin_number'],
        name: modelData['brand'],
        subtitle: modelData['model_name'],
        price: (modelData['base_price'] as num).toDouble(),
        isBike: true,
        stock: 1,
        imageUrl: modelData['image_url'], // <--- ADD THIS LINE
      );
    }).toList();

    // 2. Fetch Accessories
    final accessoriesResponse = await _supabase
        .from('product_variants')
        // ADD image_url to the select query below:
        .select(
            'id, sku, variant_name, price, stock_quantity, image_url, products(name)')
        .gt('stock_quantity', 0);

    List<Product> fetchedAccessories = accessoriesResponse.map((row) {
      final parentProduct = row['products'];
      return Product(
        id: row['id'],
        name: parentProduct['name'],
        subtitle: row['variant_name'],
        price: (row['price'] as num).toDouble(),
        isBike: false,
        stock: row['stock_quantity'] as int,
        imageUrl: row['image_url'], // <--- ADD THIS LINE
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
        // We added 'id' and 'image_url' inside the bike_models() block below:
        .select(
            'vin_number, engine_number, color, status, warehouse_location, bike_models(id, brand, model_name, base_price, image_url)')
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

  // --- UPDATE THIS EXISTING METHOD ---
  Future<void> updateAccessory(String sku, double price, int stock,
      {String? imageUrl}) async {
    // We create a map of updates. If an image was uploaded, we include it.
    final updates = <String, dynamic>{'price': price, 'stock_quantity': stock};

    if (imageUrl != null) {
      updates['image_url'] = imageUrl;
    }

    await _supabase.from('product_variants').update(updates).eq('sku', sku);
  }

  Future<void> updateMotorcycle({
    required String vin,
    required String modelId,
    required String status,
    required double price,
    String? imageUrl,
  }) async {
    // 1. Update the specific unit's status in the 'bikes' table
    await _supabase
        .from('bikes')
        .update({'status': status}).eq('vin_number', vin);

    // 2. Update the parent model's price and image in the 'bike_models' table
    final modelUpdates = <String, dynamic>{'base_price': price};

    if (imageUrl != null) {
      modelUpdates['image_url'] = imageUrl;
    }

    await _supabase.from('bike_models').update(modelUpdates).eq('id', modelId);
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

  // --- ADD THIS NEW UPLOAD METHOD ---
  Future<String?> uploadImage(String fileName, Uint8List fileBytes) async {
    try {
      // Create a unique file path so uploads don't overwrite each other
      final filePath =
          'inventory/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Upload the binary data to the 'product-images' bucket
      await _supabase.storage.from('product-images').uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Return the public URL so we can save it to the SQL database
      return _supabase.storage.from('product-images').getPublicUrl(filePath);
    } catch (e) {
      print('Image upload failed: $e');
      return null;
    }
  }
}
