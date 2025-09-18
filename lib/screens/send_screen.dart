import 'package:flutter/material.dart';
import '../services/nearby_service.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _amountController = TextEditingController();
  final _nearby = NearbyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Send Money")),
      body: StreamBuilder<List<NearbyDevice>>(
        stream: _nearby.devicesStream,
        builder: (context, snapshot) {
          final devices = snapshot.data ?? [];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Amount",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: devices.isEmpty
                    ? const Center(child: Text("🔍 Searching for nearby devices..."))
                    : ListView.builder(
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return ListTile(
                            leading: const Icon(Icons.smartphone),
                            title: Text(device.name),
                            subtitle: Text("ID: ${device.endpointId}"),
                            trailing: IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () async {
                                final amount = double.tryParse(_amountController.text);
                                if (amount == null) return;

                                await _nearby.requestConnection("Me", device.endpointId);
                                await _nearby.sendTransactionTo(
                                  endpointId: device.endpointId,
                                  sender: "Me",
                                  receiverName: device.name,
                                  amount: amount,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Sent $amount to ${device.name}")),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
