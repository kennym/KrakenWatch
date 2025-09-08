import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/balance.dart';
import '../models/portfolio_holding.dart';

class KrakenApi {
  static const String _baseUrl = 'https://api.kraken.com';
  
  final String _apiKey;
  final String _apiSecret;

  KrakenApi({
    required String apiKey,
    required String apiSecret,
  }) : _apiKey = apiKey, _apiSecret = apiSecret;

  Future<Map<String, double>> getTicker() async {
    const String path = '/0/public/Ticker';
    
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final Map<String, dynamic> result = jsonResponse['result'] ?? {};
      
      Map<String, double> prices = {};
      result.forEach((pair, data) {
        if (data['c'] != null && data['c'].isNotEmpty) {
          prices[pair] = double.tryParse(data['c'][0].toString()) ?? 0.0;
        }
      });
      
      return prices;
    } else {
      throw HttpException('Failed to fetch ticker: ${response.statusCode}');
    }
  }

  Future<KrakenBalance> getBalance() async {
    const String path = '/0/private/Balance';
    final String nonce = DateTime.now().millisecondsSinceEpoch.toString();
    
    final Map<String, String> data = {
      'nonce': nonce,
    };
    
    final String postData = data.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    
    final String signature = _generateSignature(path, postData, nonce);
    
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'API-Key': _apiKey,
        'API-Sign': signature,
      },
      body: postData,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      return KrakenBalance.fromJson(jsonResponse);
    } else {
      throw HttpException('Failed to fetch balance: ${response.statusCode}');
    }
  }

  String _generateSignature(String path, String postData, String nonce) {
    final String message = nonce + postData;
    final List<int> hash = sha256.convert(utf8.encode(message)).bytes;
    final List<int> pathBytes = utf8.encode(path);
    final List<int> combined = pathBytes + hash;
    
    final List<int> secretBytes = base64.decode(_apiSecret);
    final Hmac hmac = Hmac(sha512, secretBytes);
    final List<int> signature = hmac.convert(combined).bytes;
    
    return base64.encode(signature);
  }

  double parseBalance(Map<String, String> balances, String currency) {
    final String? balanceStr = balances[currency];
    if (balanceStr == null || balanceStr.isEmpty) {
      return 0.0;
    }
    return double.tryParse(balanceStr) ?? 0.0;
  }

  double calculateTotalInUsdt(Map<String, String> balances) {
    double total = 0.0;
    // Check all USD-related balance types
    total += parseBalance(balances, 'USDT');      // Regular USDT
    total += parseBalance(balances, 'USDT.F');    // USDT Futures
    total += parseBalance(balances, 'USDT.S');    // USDT Staking
    total += parseBalance(balances, 'ZUSDT');     // Legacy USDT code
    total += parseBalance(balances, 'ZUSD');      // USD
    total += parseBalance(balances, 'USD.F');     // USD Futures
    total += parseBalance(balances, 'USD.M');     // USD Margin
    total += parseBalance(balances, 'USDC');      // USDC
    total += parseBalance(balances, 'USDC.F');    // USDC Futures
    return total;
  }

  double calculateTotalInBtc(Map<String, String> balances) {
    double total = 0.0;
    // Check all BTC-related balance types
    total += parseBalance(balances, 'XBT');       // Regular BTC
    total += parseBalance(balances, 'XBT.M');     // BTC Margin
    total += parseBalance(balances, 'XBT.F');     // BTC Futures
    total += parseBalance(balances, 'XBT.S');     // BTC Staking
    total += parseBalance(balances, 'XXBT');      // Legacy BTC code
    return total;
  }

  double calculatePortfolioValueInUsd(Map<String, String> balances, Map<String, double> prices) {
    double totalUsd = 0.0;
    
    balances.forEach((currency, balanceStr) {
      final balance = parseBalance(balances, currency);
      if (balance <= 0) return;
      
      // Handle USD-based currencies directly
      if (_isUsdCurrency(currency)) {
        totalUsd += balance;
        return;
      }
      
      // Find the appropriate trading pair to get USD price
      final usdPrice = _findUsdPrice(currency, prices);
      if (usdPrice > 0) {
        totalUsd += balance * usdPrice;
      }
    });
    
    return totalUsd;
  }

  bool _isUsdCurrency(String currency) {
    return currency.startsWith('USD') || 
           currency.startsWith('ZUSD') || 
           currency == 'USDT' || 
           currency.startsWith('USDT.') ||
           currency == 'USDC' || 
           currency.startsWith('USDC.');
  }

  double _findUsdPrice(String currency, Map<String, double> prices) {
    // Remove suffixes like .F, .S, .M, .P to get base currency
    String baseCurrency = currency.split('.')[0];
    
    // First try direct USD pairs
    double directPrice = _findDirectUsdPrice(baseCurrency, prices);
    if (directPrice > 0) return directPrice;
    
    // If no direct USD pair, try BTC route: Asset → BTC → USD
    double btcPrice = _findBtcPrice(baseCurrency, prices);
    if (btcPrice > 0) {
      double btcToUsd = _getBtcUsdPrice(prices);
      if (btcToUsd > 0) {
        return btcPrice * btcToUsd;
      }
    }
    
    // If no BTC pair, try ETH route: Asset → ETH → USD
    double ethPrice = _findEthPrice(baseCurrency, prices);
    if (ethPrice > 0) {
      double ethToUsd = _getEthUsdPrice(prices);
      if (ethToUsd > 0) {
        return ethPrice * ethToUsd;
      }
    }
    
    return 0.0;
  }

  double _findDirectUsdPrice(String baseCurrency, Map<String, double> prices) {
    // Try different USD pair formats that Kraken uses
    final possiblePairs = [
      '${baseCurrency}USD',
      '${baseCurrency}USDT',
      '${baseCurrency}ZUSD',
      'X${baseCurrency}ZUSD',
      'X${baseCurrency}ZUSDT',
    ];
    
    for (final pair in possiblePairs) {
      if (prices.containsKey(pair)) {
        return prices[pair]!;
      }
    }
    
    return 0.0;
  }

  double _findBtcPrice(String baseCurrency, Map<String, double> prices) {
    final possiblePairs = [
      '${baseCurrency}XBT',
      '${baseCurrency}BTC',
      'X${baseCurrency}XXBT',
      '${baseCurrency}XXBT',
    ];
    
    for (final pair in possiblePairs) {
      if (prices.containsKey(pair)) {
        return prices[pair]!;
      }
    }
    
    return 0.0;
  }

  double _findEthPrice(String baseCurrency, Map<String, double> prices) {
    final possiblePairs = [
      '${baseCurrency}ETH',
      '${baseCurrency}XETH',
      'X${baseCurrency}XETH',
    ];
    
    for (final pair in possiblePairs) {
      if (prices.containsKey(pair)) {
        return prices[pair]!;
      }
    }
    
    return 0.0;
  }

  double _getBtcUsdPrice(Map<String, double> prices) {
    final btcUsdPairs = ['XBTUSD', 'XXBTZUSD', 'BTCUSD'];
    
    for (final pair in btcUsdPairs) {
      if (prices.containsKey(pair)) {
        return prices[pair]!;
      }
    }
    
    return 0.0;
  }

  double _getEthUsdPrice(Map<String, double> prices) {
    final ethUsdPairs = ['ETHUSD', 'XETHZUSD', 'XETHUSD'];
    
    for (final pair in ethUsdPairs) {
      if (prices.containsKey(pair)) {
        return prices[pair]!;
      }
    }
    
    return 0.0;
  }

  double convertUsdToBtc(double usdValue, Map<String, double> prices) {
    // Try to find BTC/USD price
    final btcUsdPairs = ['XBTUSD', 'XXBTZUSD', 'BTCUSD'];
    
    for (final pair in btcUsdPairs) {
      if (prices.containsKey(pair)) {
        final btcPrice = prices[pair]!;
        if (btcPrice > 0) {
          return usdValue / btcPrice;
        }
      }
    }
    
    return 0.0;
  }

  List<PortfolioHolding> calculatePortfolioHoldings(Map<String, String> balances, Map<String, double> prices) {
    List<PortfolioHolding> holdings = [];
    double totalPortfolioValue = 0.0;
    
    // Get BTC/USD rate for conversions
    final btcUsdRate = _getBtcUsdPrice(prices);
    
    // First pass: calculate total portfolio value
    balances.forEach((currency, balanceStr) {
      final balance = parseBalance(balances, currency);
      if (balance <= 0) return;
      
      if (_isUsdCurrency(currency)) {
        totalPortfolioValue += balance;
      } else {
        final usdPrice = _findUsdPrice(currency, prices);
        if (usdPrice > 0) {
          totalPortfolioValue += balance * usdPrice;
        }
      }
    });
    
    // Second pass: create holdings with percentages and BTC values
    balances.forEach((currency, balanceStr) {
      final balance = parseBalance(balances, currency);
      if (balance <= 0) return;
      
      double usdPrice = 0.0;
      double usdValue = 0.0;
      double btcPrice = 0.0;
      double btcValue = 0.0;
      bool isPriced = true;
      
      if (_isUsdCurrency(currency)) {
        usdPrice = 1.0;
        usdValue = balance;
        // Convert USD to BTC
        if (btcUsdRate > 0) {
          btcPrice = 1.0 / btcUsdRate;
          btcValue = balance / btcUsdRate;
        }
      } else {
        usdPrice = _findUsdPrice(currency, prices);
        if (usdPrice > 0) {
          usdValue = balance * usdPrice;
          // Convert to BTC: (amount * USD price) / BTC-USD rate
          if (btcUsdRate > 0) {
            btcPrice = usdPrice / btcUsdRate;
            btcValue = usdValue / btcUsdRate;
          }
        } else {
          isPriced = false;
        }
      }
      
      final portfolioPercentage = totalPortfolioValue > 0 
          ? (usdValue / totalPortfolioValue) * 100 
          : 0.0;
      
      holdings.add(PortfolioHolding(
        currency: currency,
        balance: balance,
        usdPrice: isPriced ? usdPrice : null,
        usdValue: usdValue,
        btcPrice: (isPriced && btcUsdRate > 0) ? btcPrice : null,
        btcValue: btcValue,
        portfolioPercentage: portfolioPercentage,
        isPriced: isPriced,
      ));
    });
    
    // Sort by USD value (descending)
    holdings.sort((a, b) => b.usdValue.compareTo(a.usdValue));
    
    return holdings;
  }
}