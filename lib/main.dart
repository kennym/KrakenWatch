import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/animated_kraken_logo.dart';
import 'widgets/portfolio_value_card.dart';
import 'widgets/holdings_list.dart';
import 'providers/portfolio_providers.dart';
import 'utils/time_formatter.dart';

void main() {
  runApp(const ProviderScope(child: KrakenWatchApp()));
}

class KrakenWatchApp extends StatelessWidget {
  const KrakenWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KrakenWatch',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5741D9), // Kraken's signature purple
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: const Color(0xFF2A2A2A),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: const Color(0xFF5741D9).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
      ),
      home: const PortfolioScreen(),
    );
  }
}

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioState = ref.watch(portfolioProvider);
    final privacyMode = ref.watch(privacyModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedKrakenLogo(
              width: 32,
              height: 32,
            ),
            SizedBox(width: 8),
            Text('KrakenWatch'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () => ref.read(privacyModeProvider.notifier).update((state) => !state),
            icon: Icon(
              privacyMode ? Icons.visibility_off : Icons.visibility,
            ),
            tooltip: privacyMode ? 'Show values' : 'Hide values',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(portfolioProvider.notifier).refreshPortfolio();
        },
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (portfolioState.lastRefresh != null)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: Text(
                      'Last updated: ${TimeFormatter.formatTime(portfolioState.lastRefresh!)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const PortfolioValueCard(),
                  const SizedBox(height: 20),
                  if (portfolioState.errorMessage != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          portfolioState.errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ),
                  if (portfolioState.errorMessage != null) const SizedBox(height: 20),
                  const HoldingsList(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
