import 'dart:async';
import 'dart:typed_data';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';
import '../models/payment_transaction.dart';

class NearbyDevice {
  final String endpointId;
  final String name;
  NearbyDevice({required this.endpointId, required this.name});
}

class NearbyService {
  static final NearbyService _instance = NearbyService._internal();
  factory NearbyService() => _instance;
  NearbyService._internal();

  final Strategy strategy = Strategy.P2P_CLUSTER;
  final DatabaseHelper db = DatabaseHelper();
  final Uuid uuid = const Uuid();

  final _devices = <String, NearbyDevice>{};
  final _devicesController = StreamController<List<NearbyDevice>>.broadcast();
  Stream<List<NearbyDevice>> get devicesStream => _devicesController.stream;

  // 👉 Stream for incoming transactions
  final _incomingController = StreamController<PaymentTransaction>.broadcast();
  Stream<PaymentTransaction> get incomingTransactions =>
      _incomingController.stream;

  bool _advertising = false;
  bool _discovering = false;

  /// Start advertising + discovery
  Future<void> startAdvertisingAndDiscovery(String userName) async {
    if (_advertising && _discovering) return;

    try {
      await Nearby().startAdvertising(
        userName,
        strategy,
        onConnectionInitiated: (endpointId, connectionInfo) {
          Nearby().acceptConnection(
            endpointId,
            onPayLoadRecieved: (id, payload) async {
              if (payload.type == PayloadType.BYTES) {
                final data = String.fromCharCodes(payload.bytes!);
                try {
                  final tx = PaymentTransaction.fromJson(data);
                  await db.insertTransaction(tx);
                  _incomingController.add(tx); // broadcast incoming
                  print("📥 Received transaction: ${tx.amount} from ${tx.sender}");
                } catch (e) {
                  print("❌ Error parsing transaction: $e");
                }
              }
            },
          );
        },
        onConnectionResult: (id, status) {
          print("Connection result [$id]: $status");
        },
        onDisconnected: (id) {
          print("Disconnected from $id");
        },
      );
      _advertising = true;
    } catch (e) {
      print("❌ Error starting advertising: $e");
    }

    try {
      await Nearby().startDiscovery(
        uuid.v4(),
        strategy,
        onEndpointFound: (id, name, serviceId) {
          _devices[id] = NearbyDevice(endpointId: id, name: name);
          _pushDevices();
        },
        onEndpointLost: (id) {
          _devices.remove(id);
          _pushDevices();
        },
      );
      _discovering = true;
    } catch (e) {
      print("❌ Error starting discovery: $e");
    }
  }

  void _pushDevices() {
    _devicesController.add(_devices.values.toList());
  }

  Future<void> stopAll() async {
    try {
      if (_advertising) {
        await Nearby().stopAdvertising();
        _advertising = false;
      }
      if (_discovering) {
        await Nearby().stopDiscovery();
        _discovering = false;
      }
      _devices.clear();
      _pushDevices();
    } catch (e) {
      print("❌ Error stopping services: $e");
    }
  }

  Future<void> requestConnection(String name, String endpointId) async {
    try {
      await Nearby().requestConnection(
        name,
        endpointId,
        onConnectionInitiated: (id, info) {
          Nearby().acceptConnection(
            id,
            onPayLoadRecieved: (cid, payload) async {
              if (payload.type == PayloadType.BYTES) {
                final data = String.fromCharCodes(payload.bytes!);
                try {
                  final tx = PaymentTransaction.fromJson(data);
                  await db.insertTransaction(tx);
                  _incomingController.add(tx); // broadcast incoming
                  print("📥 Received transaction: ${tx.amount}");
                } catch (e) {
                  print("❌ Error parsing transaction: $e");
                }
              }
            },
          );
        },
        onConnectionResult: (id, status) {
          print("Connection result [$id]: $status");
        },
        onDisconnected: (id) {
          print("Disconnected from $id");
        },
      );
    } catch (e) {
      print("❌ Error requesting connection: $e");
    }
  }

  Future<void> sendTransactionTo({
    required String endpointId,
    required String sender,
    required String receiverName,
    required double amount,
    String note = "",
  }) async {
    final tx = PaymentTransaction(
      id: uuid.v4(),
      sender: sender,
      receiver: receiverName,
      amount: amount,
      note: note,
      timestamp: DateTime.now(),
      status: "pending",
    );

    await db.insertTransaction(tx);

    try {
      await Nearby().sendBytesPayload(
        endpointId,
        Uint8List.fromList(tx.toJson().codeUnits),
      );
      print("📤 Sent transaction: ${tx.amount} to $receiverName");
    } catch (e) {
      print("❌ Error sending payload: $e");
    }
  }

  void dispose() {
    _devicesController.close();
    _incomingController.close();
  }
}
