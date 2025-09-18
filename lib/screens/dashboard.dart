import 'dart:async';
import 'package:flutter/material.dart';
import '../services/nearby_service.dart';
import 'device_list_screen.dart';
import 'history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  final NearbyService _nearby = NearbyService();
  StreamSubscription? _devicesSub;
  List<NearbyDevice> _devices = [];
  String _myName = "Me";
  double _balance = 25000.00; // demo balance

  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    // start advertising & discovery (idempotent)
    _nearby.startAdvertisingAndDiscovery(_myName);
    _devicesSub = _nearby.devicesStream.listen((list) {
      setState(() {
        _devices = list;
      });
    });
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    _scanController.dispose();
    super.dispose();
  }

  void _openDeviceList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DeviceListScreen(myName: _myName)),
    );
  }

  Widget _accountCard() {
    final accent = Theme.of(context).colorScheme.secondary;
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Allied Pay", style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
                CircleAvatar(backgroundColor: accent, child: const Icon(Icons.person, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 14),
            Text("Available balance", style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("PKR ", style: TextStyle(color: Colors.black54, fontSize: 16)),
                Text(_balance.toStringAsFixed(2), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: accent)),
              ],
            ),
            const SizedBox(height: 12),
            Text("Account •••• 1234", style: TextStyle(color: Colors.black45)),
          ],
        ),
      ),
    );
  }

  Widget _quickActions() {
    final accent = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openDeviceList,
              icon: const Icon(Icons.person),
              label: const Text("Send Money"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
            child: const Icon(Icons.history),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black87, padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ],
      ),
    );
  }

  Widget _deviceSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Nearby People", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _devices.isEmpty
              ? SizedBox(
                  height: 140,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RotationTransition(
                          turns: _scanController,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.12), width: 8)),
                            child: Center(child: Icon(Icons.person_search, size: 36, color: Theme.of(context).primaryColor)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("Searching for nearby people..."),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (ctx, i) {
                      final d = _devices[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeviceListScreen(myName: _myName, preselectedDevice: d))),
                        child: Container(
                          width: 120,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircleAvatar(radius: 26, child: Icon(Icons.person, size: 28)),
                              const SizedBox(height: 8),
                              Text(d.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(d.endpointId.length > 6 ? d.endpointId.substring(0, 6) + "..." : d.endpointId, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: _devices.length,
                  ),
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            title: const Text("Allied Pay"),
            actions: [
              IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())), icon: const Icon(Icons.notifications)),
            ],
            backgroundColor: Theme.of(context).primaryColor,
            expandedHeight: 0,
          ),
          SliverToBoxAdapter(child: _accountCard()),
          SliverToBoxAdapter(child: const SizedBox(height: 8)),
          SliverToBoxAdapter(child: _quickActions()),
          SliverToBoxAdapter(child: _deviceSection()),
          SliverToBoxAdapter(child: const SizedBox(height: 32)),
        ],
      ),
    );
  }
}
