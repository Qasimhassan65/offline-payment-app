import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/payment_transaction.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final db = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transaction History")),
      body: FutureBuilder<List<PaymentTransaction>>(
        future: db.getTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final txs = snapshot.data!;
          if (txs.isEmpty) {
            return const Center(child: Text("No transactions yet."));
          }
          return ListView.builder(
            itemCount: txs.length,
            itemBuilder: (context, index) {
              final tx = txs[index];
              return ListTile(
                leading: const Icon(Icons.attach_money),
                title: Text("${tx.amount} → ${tx.receiver}"),
                subtitle: Text(
                  DateFormat('yyyy-MM-dd HH:mm:ss').format(tx.timestamp),
                ),
                trailing: Text(tx.status),
              );
            },
          );
        },
      ),
    );
  }
}
