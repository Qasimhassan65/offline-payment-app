import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/dashboard.dart';
import 'screens/history_screen.dart';
import 'services/nearby_service.dart';
import 'models/payment_transaction.dart';

final GlobalKey<NavigatorState> rootNavKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();
  runApp(const AlliedPayApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.locationWhenInUse,
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothAdvertise,
    Permission.bluetoothConnect,
    Permission.nearbyWifiDevices,
  ].request();
}

class AlliedPayApp extends StatefulWidget {
  const AlliedPayApp({super.key});

  @override
  State<AlliedPayApp> createState() => _AlliedPayAppState();
}

class _AlliedPayAppState extends State<AlliedPayApp> {
  final NearbyService _nearby = NearbyService();

  @override
  void initState() {
    super.initState();
    // Start nearby (will be no-op if permissions missing)
    // We start advertising/discovery from Dashboard when it initializes as well.
    // Subscribe to incoming transactions to show an incoming dialog globally.
    try {
      _nearby.incomingTransactions.listen((PaymentTransaction tx) {
        _showIncoming(tx);
      });
    } catch (_) {}
  }

  Future<void> _showIncoming(PaymentTransaction tx) async {
    // Use navigatorKey to show dialog even if another screen is active
    final ctx = rootNavKey.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      builder: (_) {
        return AlertDialog(
          title: const Text("Incoming payment"),
          content: Text(
            "${tx.sender} → ${tx.receiver}\nPKR ${tx.amount.toStringAsFixed(2)}\n${tx.note}",
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF003366); // Allied deep navy
    final accent = const Color(0xFFFF6600); // Allied orange

    return MaterialApp(
      navigatorKey: rootNavKey,
      title: 'Allied Pay (Demo)',
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: primary,
        colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary, secondary: accent),
        appBarTheme: AppBarTheme(backgroundColor: primary, foregroundColor: Colors.white),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF003366)),
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const RootNav(),
        '/history': (_) => const HistoryScreen(),
      },
    );
  }

  @override
  void dispose() {
    _nearby.dispose();
    super.dispose();
  }
}

/// RootNav holds bottom navigation and swaps between dashboard/history
class RootNav extends StatefulWidget {
  const RootNav({super.key});
  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;
  final pages = [
    const DashboardScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final navy = Theme.of(context).primaryColor;

    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: accent,
        unselectedItemColor: Colors.black54,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: const Icon(Icons.list), label: "History"),
        ],
      ),
    );
  }
}
