import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/portfolio_providers.dart';

class PortfolioValueCard extends ConsumerWidget {
  const PortfolioValueCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioState = ref.watch(portfolioProvider);
    final privacyMode = ref.watch(privacyModeProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    '💰USDT',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                Flexible(
                  child: Text(
                    privacyMode 
                        ? 'Hidden for privacy' 
                        : '\$${portfolioState.portfolioValueUsdt.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: privacyMode ? Colors.grey : Colors.green,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    '₿ BTC',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                Flexible(
                  child: Text(
                    privacyMode 
                        ? 'Hidden for privacy' 
                        : '₿${portfolioState.portfolioValueBtc.toStringAsFixed(8)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: privacyMode ? Colors.grey : Colors.orange,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}