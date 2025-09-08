class PortfolioHolding {
  final String currency;
  final double balance;
  final double? usdPrice;
  final double usdValue;
  final double? btcPrice;
  final double btcValue;
  final double portfolioPercentage;
  final bool isPriced;

  PortfolioHolding({
    required this.currency,
    required this.balance,
    this.usdPrice,
    required this.usdValue,
    this.btcPrice,
    required this.btcValue,
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
        'F': 'Kraken Rewards',    // Auto-earning rewards
        'S': 'Legacy Staking',    // Legacy staking system
        'M': 'Opt-in Rewards',    // Opt-in rewards assets
        'B': 'Yield-Bearing',     // New yield-bearing products
        'T': 'Tokenized',         // Tokenized assets
        'P': 'Perpetual',         // Keep this for any actual perpetual futures
      };
      return suffixMap[parts[1]] ?? parts[1];
    }
    return '';
  }

  String get fullDisplayName {
    final suffix = this.suffix;
    return suffix.isEmpty ? displayName : '$displayName ($suffix)';
  }

  String formatBtcValue() {
    if (btcValue == 0) return '₿0.00000000';
    
    // For values >= 0.01 BTC, show 4 decimal places
    if (btcValue >= 0.01) {
      return '₿${btcValue.toStringAsFixed(4)}';
    }
    // For smaller values, show 8 decimal places
    else {
      return '₿${btcValue.toStringAsFixed(8)}';
    }
  }

  String formatUsdValue() {
    if (usdValue == 0) return '\$0.00';
    
    // For values >= $1, show 2 decimal places
    if (usdValue >= 1.0) {
      return '\$${usdValue.toStringAsFixed(2)}';
    }
    // For smaller values, show more precision
    else if (usdValue >= 0.01) {
      return '\$${usdValue.toStringAsFixed(4)}';
    }
    else {
      return '\$${usdValue.toStringAsFixed(6)}';
    }
  }
}