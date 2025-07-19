import 'package:flutter/material.dart';

class NotificationsBanner extends StatelessWidget {
  final String? budgetWarning;
  final String? reminder;
  const NotificationsBanner({super.key, this.budgetWarning, this.reminder});
  @override
  Widget build(BuildContext context) {
    if (budgetWarning == null && reminder == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: budgetWarning != null ? Colors.redAccent : const Color(0xFF6C2EB7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(budgetWarning != null ? Icons.warning : Icons.notifications, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              budgetWarning ?? reminder ?? '',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
} 