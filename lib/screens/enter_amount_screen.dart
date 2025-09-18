import 'package:flutter/material.dart';

class EnterAmountScreen extends StatefulWidget {
  final String recipientName;
  const EnterAmountScreen({super.key, required this.recipientName});
  @override
  State<EnterAmountScreen> createState() => _EnterAmountScreenState();
}

class _EnterAmountScreenState extends State<EnterAmountScreen> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _sending = false;

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter valid amount")));
      return;
    }
    Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(title: Text("Send to ${widget.recipientName}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: Text("Amount", style: TextStyle(color: Colors.black54))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(prefixText: "PKR ", border: InputBorder.none, hintText: "0.00"),
                    ),
                    const SizedBox(height: 8),
                    TextField(controller: _noteCtrl, decoration: const InputDecoration(labelText: "Note (optional)")),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _sending ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: accent, minimumSize: const Size.fromHeight(50)),
              child: _sending ? const CircularProgressIndicator(color: Colors.white) : const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
