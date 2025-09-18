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
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final txs = snap.data!;
          if (txs.isEmpty) return const Center(child: Text("No transactions yet."));
          return ListView.separated(
            itemCount: txs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final t = txs[i];
              return ListTile(
                leading: const Icon(Icons.attach_money),
                title: Text("PKR ${t.amount.toStringAsFixed(2)} → ${t.receiver}"),
                subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(t.timestamp)),
                trailing: Text(t.status),
              );
            },
          );
        },
      ),
    );
  }
}
