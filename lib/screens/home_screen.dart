// lib/screens/home_screen.dart
import 'dart:async';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import '../services/nearby_service.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final NearbyService _nearby = NearbyService();
  StreamSubscription? _devicesSub;
  StreamSubscription? _incomingSub;
  List<NearbyDevice> _devices = [];
  String _myName = "Me";

  // animation controller for scanning dots
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();

    _initMyName();
    _startNearby();

    _devicesSub = _nearby.devicesStream.listen((list) {
      setState(() {
        _devices = list;
      });
    });

    // only use if NearbyService exposes incomingTransactions stream
    try {
      _incomingSub = _nearby.incomingTransactions.listen((tx) {
        _showIncoming(tx);
        setState(() {});
      });
    } catch (_) {
      // incomingTransactions might not be available yet — ignore
    }
  }

  Future<void> _initMyName() async {
    final deviceInfo = DeviceInfoPlugin();
    String name = "User";

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // prefer model, fallback to device/buildModel
        name = androidInfo.model ?? androidInfo.device ?? "Android User";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        name = iosInfo.name ?? iosInfo.utsname.machine ?? "iOS User";
      }
    } catch (e) {
      debugPrint("⚠️ device info error: $e");
      name = "User";
    }

    if (mounted) {
      setState(() => _myName = name);
    }
  }

  Future<void> _startNearby() async {
    await _nearby.startAdvertisingAndDiscovery(_myName);
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    _incomingSub?.cancel();
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _showIncoming(dynamic tx) async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Incoming payment"),
        content: Text(
            "${tx.sender} → ${tx.receiver}\nPKR ${tx.amount.toStringAsFixed(2)}\n${tx.note}"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  void _onTapDevice(NearbyDevice device) {
    showDialog(
      context: context,
      builder: (_) {
        final _amountCtrl = TextEditingController();
        final _noteCtrl = TextEditingController();
        bool sending = false;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("Send to ${device.name}"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(prefixText: "PKR "),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: "Note (optional)"),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: sending ? null : () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: sending
                    ? null
                    : () async {
                        final text = _amountCtrl.text.trim();
                        final amount = double.tryParse(text);
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter valid amount")));
                          return;
                        }
                        setState(() => sending = true);
                        try {
                          await _nearby.requestConnection(_myName, device.endpointId);
                          await _nearby.sendTransactionTo(
                            endpointId: device.endpointId,
                            sender: _myName,
                            receiverName: device.name,
                            amount: amount,
                            note: _noteCtrl.text.trim(),
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sent (pending)")));
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                          }
                        } finally {
                          setState(() => sending = false);
                        }
                      },
                child: sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Send"),
              )
            ],
          );
        });
      },
    );
  }

  Widget _buildDeviceCard(NearbyDevice d) {
    return InkWell(
      onTap: () => _onTapDevice(d),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_android, size: 40),
            const SizedBox(height: 8),
            Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(d.endpointId.length > 6 ? d.endpointId.substring(0, 6) + "..." : d.endpointId, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RotationTransition(
          turns: _scanController,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.withOpacity(0.2), width: 8),
            ),
            child: const Center(child: Icon(Icons.wifi_tethering, size: 48, color: Colors.blue)),
          ),
        ),
        const SizedBox(height: 16),
        const Text("Searching for nearby devices...", style: TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        const Text("Tap a device to send money", style: TextStyle(color: Colors.black54)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text("Offline Payments"),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
          IconButton(icon: const Icon(Icons.stop_circle), onPressed: () async {
            await _nearby.stopAll();
            setState(() { _devices = []; });
          }),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: _devices.isEmpty ? Center(child: _buildSearchingView()) : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.95),
                itemCount: _devices.length,
                itemBuilder: (context, i) => _buildDeviceCard(_devices[i]),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ElevatedButton.icon(onPressed: _startNearby, icon: const Icon(Icons.refresh), label: const Text("Rescan"))),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())), child: const Icon(Icons.list)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
