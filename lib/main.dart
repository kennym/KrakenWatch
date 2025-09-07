import 'package:flutter/material.dart';
import 'services/kraken_api.dart';
import 'config/api_config.dart';
import 'models/portfolio_holding.dart';

void main() {
  runApp(const KrakenWatchApp());
}

class KrakenWatchApp extends StatelessWidget {
  const KrakenWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KrakenWatch',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PortfolioScreen(),
    );
  }
}

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  double _portfolioValueUsdt = 0.0;
  double _portfolioValueBtc = 0.0;
  List<PortfolioHolding> _holdings = [];
  bool _isLoading = false;
  String _errorMessage = '';
  DateTime? _lastRefresh;
  
  late final KrakenApi _krakenApi;

  @override
  void initState() {
    super.initState();
    _krakenApi = KrakenApi(
      apiKey: ApiConfig.krakenApiKey,
      apiSecret: ApiConfig.krakenApiSecret,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KrakenWatch'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Portfolio Value',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Portfolio Value (USDT)',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          '\$${_portfolioValueUsdt.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Portfolio Value (BTC)',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          '₿${_portfolioValueBtc.toStringAsFixed(8)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              ),
            if (_errorMessage.isNotEmpty) const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loadBalances,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Refresh Portfolio'),
              ),
            ),
            if (_lastRefresh != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Last updated: ${_formatTime(_lastRefresh!)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            if (_holdings.isNotEmpty) ...[
              const SizedBox(height: 30),
              const Text(
                'Holdings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ..._buildHoldingsList(),
            ],
          ],
        ),
      ),
    );
  }

  void _loadBalances() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Fetch both balance and market prices
      final balance = await _krakenApi.getBalance();
      final prices = await _krakenApi.getTicker();
      
      if (balance.error.isNotEmpty) {
        throw Exception('Kraken API Error: ${balance.error.join(', ')}');
      }
      
      // Calculate total portfolio value and individual holdings
      final portfolioValueUsd = _krakenApi.calculatePortfolioValueInUsd(balance.result, prices);
      final portfolioValueBtc = _krakenApi.convertUsdToBtc(portfolioValueUsd, prices);
      final holdings = _krakenApi.calculatePortfolioHoldings(balance.result, prices);
      
      setState(() {
        _portfolioValueUsdt = portfolioValueUsd;
        _portfolioValueBtc = portfolioValueBtc;
        _holdings = holdings;
        _lastRefresh = DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load portfolio: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Widget> _buildHoldingsList() {
    return _holdings.map((holding) => _buildHoldingCard(holding)).toList();
  }

  Widget _buildHoldingCard(PortfolioHolding holding) {
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
                Text(
                  holding.balance.toStringAsFixed(8),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (holding.isPriced && holding.usdValue > 0) ...[
                      Text(
                        '\$${holding.usdValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
