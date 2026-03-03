import 'dart:async';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocalDatabaseService {
  static Database? _database;
  Timer? _syncTimer;
  bool _isSyncing = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('motovault_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createSchema,
    );
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bike_models (
        id TEXT PRIMARY KEY, brand TEXT NOT NULL, model_name TEXT NOT NULL, base_price REAL NOT NULL, image_url TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE bikes (
        vin_number TEXT PRIMARY KEY, model_id TEXT, engine_number TEXT, color TEXT, status TEXT, image_url TEXT,
        FOREIGN KEY (model_id) REFERENCES bike_models (id)
      )
    ''');
    await db.execute('''
      CREATE TABLE product_variants (
        sku TEXT PRIMARY KEY, product_id TEXT, variant_name TEXT, price REAL NOT NULL, stock_quantity INTEGER NOT NULL, image_url TEXT, product_name TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT, receipt_id TEXT NOT NULL, payload TEXT NOT NULL, status TEXT DEFAULT 'pending', created_at TEXT NOT NULL
      )
    ''');
  }

  // ==========================================
  // OFFLINE READS (For the UI)
  // ==========================================

  Future<List<Map<String, dynamic>>> getLocalBikes(
      {bool onlyInStock = false}) async {
    final db = await database;
    String query = '''
      SELECT b.*, m.brand, m.model_name, m.base_price, m.image_url as model_image 
      FROM bikes b LEFT JOIN bike_models m ON b.model_id = m.id
    ''';
    if (onlyInStock) query += " WHERE b.status = 'in_stock'";
    return await db.rawQuery(query);
  }

  Future<List<Map<String, dynamic>>> getLocalAccessories() async {
    final db = await database;
    return await db.query('product_variants');
  }

  // ==========================================
  // OFFLINE WRITES (Checkout & Admin)
  // ==========================================

  Future<void> saveOfflineCheckout({
    required double subtotal,
    required double vatAmount,
    required double grandTotal,
    required String paymentType,
    required List<dynamic> cartItems,
  }) async {
    final db = await database;
    final batch = db.batch();
    final receiptId = 'REC_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Deduct local inventory instantly
    for (var item in cartItems) {
      if (item.product.isBike) {
        batch.update('bikes', {'status': 'sold'},
            where: 'vin_number = ?', whereArgs: [item.product.id]);
      } else {
        batch.rawUpdate(
            'UPDATE product_variants SET stock_quantity = stock_quantity - ? WHERE sku = ?',
            [item.quantity, item.product.id]);
      }
    }

    // 2. Package for the cloud
    final payload = {
      'subtotal': subtotal,
      'vatAmount': vatAmount,
      'grandTotal': grandTotal,
      'paymentType': paymentType,
      'items': cartItems
          .map((e) => {
                'id': e.product.id,
                'quantity': e.quantity,
                'isBike': e.product.isBike,
                'price': e.product.price
              })
          .toList(),
    };

    // 3. Queue for sync
    batch.insert('sync_queue', {
      'receipt_id': receiptId,
      'payload': jsonEncode(payload),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });

    await batch.commit(noResult: true);
  }

  // ==========================================
  // BACKGROUND SYNC ENGINE (Push & Pull)
  // ==========================================

  void startAutoSync() {
    print('🔄 Starting background sync engine...');
    _runFullSync();
    _syncTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => _runFullSync());
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('🛑 Background sync engine stopped.');
  }

  Future<void> _runFullSync() async {
    if (_isSyncing) return; // Prevent overlapping syncs
    _isSyncing = true;

    // Quick internet check (Supabase will throw if offline)
    try {
      await _pushSalesToCloud();
      await _pullInventoryFromCloud();
    } catch (e) {
      print('📴 Offline: Sync deferred. Data is safe locally.');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushSalesToCloud() async {
    final db = await database;
    final supabase = Supabase.instance.client;

    final pendingSales =
        await db.query('sync_queue', where: "status = 'pending'");
    if (pendingSales.isEmpty) return;

    for (var sale in pendingSales) {
      final payload = jsonDecode(sale['payload'] as String);

      try {
        // 1. Create Sale Record in Supabase
        // 1. Create Sale Record in Supabase
        await supabase.from('sales_orders').insert({
          'subtotal': payload['subtotal'],
          'vat_amount': payload['vatAmount'],
          'grand_total': payload['grandTotal'],
          'payment_type': payload['paymentType'].toString().toLowerCase(),
          'created_at': sale['created_at'],
        });

        // (We removed the .select() and the orderId variable entirely)

        // 2. Process Items in the cloud
        for (var item in payload['items']) {
          if (item['isBike']) {
            await supabase
                .from('bikes')
                .update({'status': 'sold'}).eq('vin_number', item['id']);
          } else {
            // Decrement cloud stock via RPC (or select/update if RPC isn't setup)
            final currentItem = await supabase
                .from('product_variants')
                .select('stock_quantity')
                .eq('sku', item['id'])
                .single();
            await supabase.from('product_variants').update({
              'stock_quantity': currentItem['stock_quantity'] - item['quantity']
            }).eq('sku', item['id']);
          }
        }

        // 3. Delete from local queue upon success
        await db.delete('sync_queue', where: 'id = ?', whereArgs: [sale['id']]);
        print('✅ Pushed receipt ${sale['receipt_id']} to cloud!');
      } catch (e) {
        print('❌ Failed to push sale ${sale['receipt_id']}: $e');
        // Will retry on next timer tick
      }
    }
  }

  Future<void> _pullInventoryFromCloud() async {
    final supabase = Supabase.instance.client;
    final db = await database;

    final models = await supabase.from('bike_models').select();
    final bikes = await supabase.from('bikes').select();
    final accessories =
        await supabase.from('product_variants').select('*, products(name)');

    final batch = db.batch();

    for (var m in models) {
      batch.insert(
          'bike_models',
          {
            'id': m['id'],
            'brand': m['brand'],
            'model_name': m['model_name'],
            'base_price': m['base_price'],
            'image_url': m['image_url']
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (var b in bikes) {
      batch.insert(
          'bikes',
          {
            'vin_number': b['vin_number'],
            'model_id': b['model_id'],
            'engine_number': b['engine_number'],
            'color': b['color'],
            'status': b['status'],
            'image_url': b['image_url']
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (var a in accessories) {
      batch.insert(
          'product_variants',
          {
            'sku': a['sku'],
            'product_id': a['product_id'],
            'variant_name': a['variant_name'],
            'price': a['price'],
            'stock_quantity': a['stock_quantity'],
            'image_url': a['image_url'],
            'product_name': a['products']?['name'] ?? 'Gear'
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
    print('📥 Cloud inventory synced locally.');
  }
}
