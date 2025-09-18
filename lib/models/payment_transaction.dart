// lib/models/payment_transaction.dart
import 'dart:convert';

class PaymentTransaction {
  final String id;
  final String sender;
  final String receiver;
  final double amount;
  final String note;
  final DateTime timestamp;
  String status; // "pending" or "acknowledged"

  PaymentTransaction({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.amount,
    required this.note,
    required this.timestamp,
    this.status = "pending",
  });

  Map<String, dynamic> toMap() => {
        "id": id,
        "sender": sender,
        "receiver": receiver,
        "amount": amount,
        "note": note,
        "timestamp": timestamp.toIso8601String(),
        "status": status,
      };

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) {
    return PaymentTransaction(
      id: map["id"],
      sender: map["sender"],
      receiver: map["receiver"],
      amount: (map["amount"] as num).toDouble(),
      note: map["note"] ?? "",
      timestamp: DateTime.parse(map["timestamp"]),
      status: map["status"] ?? "pending",
    );
  }

  String toJson() => jsonEncode(toMap());
  factory PaymentTransaction.fromJson(String source) =>
      PaymentTransaction.fromMap(jsonDecode(source));
}
