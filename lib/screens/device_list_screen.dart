import 'package:flutter/material.dart';
import '../services/nearby_service.dart';
import 'enter_amount_screen.dart';

class DeviceListScreen extends StatefulWidget {
  final String myName;
  final NearbyDevice? preselectedDevice;
  const DeviceListScreen({super.key, required this.myName, this.preselectedDevice});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  final NearbyService _nearby = NearbyService();
  List<NearbyDevice> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _nearby.startAdvertisingAndDiscovery(widget.myName);
    _nearby.devicesStream.listen((list) {
      setState(() {
        _devices = list;
        _loading = false;
      });
    });

    // if a device was preselected (from dashboard quick tap) open amount screen directly
    if (widget.preselectedDevice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onSelect(widget.preselectedDevice!);
      });
    }
  }

  Future<void> _onSelect(NearbyDevice device) async {
    final result = await Navigator.push<double?>(
      context,
      MaterialPageRoute(builder: (_) => EnterAmountScreen(recipientName: device.name)),
    );

    if (result != null && result > 0) {
      await _nearby.requestConnection(widget.myName, device.endpointId);
      await _nearby.sendTransactionTo(
        endpointId: device.endpointId,
        sender: widget.myName,
        receiverName: device.name,
        amount: result,
        note: "Sent via Allied Pay",
      );
      // show success toast/snack
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PKR ${result.toStringAsFixed(2)} sent to ${device.name}")));
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _deviceCard(NearbyDevice d) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(d.name),
        subtitle: Text(d.endpointId.length > 10 ? d.endpointId.substring(0, 10) + "..." : d.endpointId),
        trailing: ElevatedButton.icon(
          onPressed: () => _onSelect(d),
          icon: const Icon(Icons.send),
          label: const Text("Send"),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Money"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [Icon(Icons.person_search, size: 48), SizedBox(height: 12), Text("No nearby people found")],
                ))
              : ListView.builder(itemCount: _devices.length, itemBuilder: (ctx, i) => _deviceCard(_devices[i])),
    );
  }
}
