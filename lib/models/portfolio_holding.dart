class PortfolioHolding {
  final String currency;
  final double balance;
  final double? usdPrice;
  final double usdValue;
  final double portfolioPercentage;
  final bool isPriced;

  PortfolioHolding({
    required this.currency,
    required this.balance,
    this.usdPrice,
    required this.usdValue,
    required this.portfolioPercentage,
    required this.isPriced,
  });

  String get displayName {
    // Remove Kraken suffixes for cleaner display
    String clean = currency.split('.')[0];
    
    // Handle Kraken's currency name mappings
    const currencyMap = {
      'XXBT': 'BTC',
      'XETH': 'ETH',
      'XXRP': 'XRP',
      'XXDG': 'DOGE',
      'ZUSD': 'USD',
      'ZEUR': 'EUR',
    };
    
    return currencyMap[clean] ?? clean;
  }

  String get suffix {
    final parts = currency.split('.');
    if (parts.length > 1) {
      final suffixMap = {
        'F': 'Futures',
        'S': 'Staking', 
        'M': 'Margin',
        'P': 'Perpetual',
      };
      return suffixMap[parts[1]] ?? parts[1];
    }
    return '';
  }

  String get fullDisplayName {
    final suffix = this.suffix;
    return suffix.isEmpty ? displayName : '$displayName ($suffix)';
  }
}