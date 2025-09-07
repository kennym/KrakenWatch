import 'package:flutter/material.dart';
import 'services/kraken_api.dart';
import 'config/api_config.dart';

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
  bool _isLoading = false;
  String _errorMessage = '';
  
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
      body: Padding(
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
                    : const Text('Refresh Balances'),
              ),
            ),
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
      
      // Calculate total portfolio value
      final portfolioValueUsd = _krakenApi.calculatePortfolioValueInUsd(balance.result, prices);
      final portfolioValueBtc = _krakenApi.convertUsdToBtc(portfolioValueUsd, prices);
      
      setState(() {
        _portfolioValueUsdt = portfolioValueUsd;
        _portfolioValueBtc = portfolioValueBtc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load portfolio: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}
