import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/portfolio_holding.dart';
import '../providers/portfolio_providers.dart';

class HoldingCard extends ConsumerWidget {
  final PortfolioHolding holding;

  const HoldingCard({
    super.key,
    required this.holding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacyMode = ref.watch(privacyModeProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    holding.fullDisplayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (holding.portfolioPercentage > 0)
                  Text(
                    '${holding.portfolioPercentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (privacyMode) ...[
                  // In privacy mode, show "Hidden for privacy"
                  Text(
                    'Hidden for privacy',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ] else ...[
                  // In normal mode, show balance
                  Text(
                    holding.balance.toStringAsFixed(8),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (privacyMode) ...[
                      // In privacy mode, only show "Hidden for privacy"
                      Text(
                        'Hidden for privacy',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ] else ...[
                      // In normal mode, show full values
                      if (holding.isPriced && holding.usdValue > 0) ...[
                        // USD and BTC values side by side
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              holding.formatUsdValue(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                            const Text(
                              ' | ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              holding.formatBtcValue(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        if (holding.usdPrice != null && holding.usdPrice! != 1.0)
                          Text(
                            '@\$${holding.usdPrice!.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                      ] else ...[
                        Text(
                          'No price data',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}