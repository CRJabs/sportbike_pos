import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  // 1. Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Load Environment Variables safely
  await dotenv.load(fileName: ".env");

  // 3. Initialize Supabase Connection
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  // 4. Run App inside ProviderScope for state management
  runApp(const ProviderScope(child: SportbikePOSApp()));
}

class SportbikePOSApp extends StatelessWidget {
  const SportbikePOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sportbike POS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Supabase Connected. Ready to build.'),
        ),
      ),
    );
  }
}
