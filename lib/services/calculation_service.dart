import '../models/portfolio_holding.dart';

class CalculationService {
  static double parseBalance(Map<String, String> balances, String currency) {
    final String? balanceStr = balances[currency];
    if (balanceStr == null || balanceStr.isEmpty) {
      return 0.0;
    }
    return double.tryParse(balanceStr) ?? 0.0;
  }

  static double calculatePortfolioValueInUsd(
    Map<String, String> balances, 
    Map<String, double> prices,
  ) {
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

  static double convertUsdToBtc(double usdValue, Map<String, double> prices) {
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

  static List<PortfolioHolding> calculatePortfolioHoldings(
    Map<String, String> balances, 
    Map<String, double> prices,
  ) {
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

  static bool _isUsdCurrency(String currency) {
    return currency.startsWith('USD') || 
           currency.startsWith('ZUSD') || 
           currency == 'USDT' || 
           currency.startsWith('USDT.') ||
           currency == 'USDC' || 
           currency.startsWith('USDC.');
  }

  static double _findUsdPrice(String currency, Map<String, double> prices) {
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

  static double _findDirectUsdPrice(String baseCurrency, Map<String, double> prices) {
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

  static double _findBtcPrice(String baseCurrency, Map<String, double> prices) {
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

  static double _findEthPrice(String baseCurrency, Map<String, double> prices) {
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

  static double _getBtcUsdPrice(Map<String, double> prices) {
    final btcUsdPairs = ['XBTUSD', 'XXBTZUSD', 'BTCUSD'];
    
    for (final pair in btcUsdPairs) {
      if (prices.containsKey(pair)) {
        return prices[pair]!;
      }
    }
    
    return 0.0;
  }

  static double _getEthUsdPrice(Map<String, double> prices) {
    final ethUsdPairs = ['ETHUSD', 'XETHZUSD', 'XETHUSD'];
    
    for (final pair in ethUsdPairs) {
      if (prices.containsKey(pair)) {
        return prices[pair]!;
      }
    }
    
    return 0.0;
  }
}