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
  bool _privacyMode = true;
  
  late final KrakenApi _krakenApi;

  @override
  void initState() {
    super.initState();
    _krakenApi = KrakenApi(
      apiKey: ApiConfig.krakenApiKey,
      apiSecret: ApiConfig.krakenApiSecret,
    );
    // Auto-refresh portfolio on app start
    _loadBalances();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KrakenWatch 🦑'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadBalances,
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Refresh portfolio',
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _privacyMode = !_privacyMode;
              });
            },
            icon: Icon(
              _privacyMode ? Icons.visibility_off : Icons.visibility,
            ),
            tooltip: _privacyMode ? 'Show values' : 'Hide values',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '💰 Portfolio Value (USDT)',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          _privacyMode ? 'Hidden for privacy' : '\$${_portfolioValueUsdt.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _privacyMode ? Colors.grey : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '₿ Portfolio Value (BTC)',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          _privacyMode ? 'Hidden for privacy' : '₿${_portfolioValueBtc.toStringAsFixed(8)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _privacyMode ? Colors.grey : Colors.orange,
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
                '📊 Holdings',
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
                if (_privacyMode) ...[
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
                    if (_privacyMode) ...[
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
