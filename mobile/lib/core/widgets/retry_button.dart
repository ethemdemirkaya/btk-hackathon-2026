import 'package:flutter/material.dart';

class RetryButton extends StatelessWidget {
  final VoidCallback onRetry;
  final String label;

  const RetryButton({
    super.key,
    required this.onRetry,
    this.label = 'Tekrar Dene',
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh, size: 18),
      label: Text(label),
    );
  }
}
