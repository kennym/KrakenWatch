import 'package:flutter/foundation.dart';
import 'portfolio_holding.dart';

@immutable
class PortfolioState {
  final double portfolioValueUsdt;
  final double portfolioValueBtc;
  final List<PortfolioHolding> holdings;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastRefresh;

  const PortfolioState({
    this.portfolioValueUsdt = 0.0,
    this.portfolioValueBtc = 0.0,
    this.holdings = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastRefresh,
  });

  PortfolioState copyWith({
    double? portfolioValueUsdt,
    double? portfolioValueBtc,
    List<PortfolioHolding>? holdings,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastRefresh,
  }) {
    return PortfolioState(
      portfolioValueUsdt: portfolioValueUsdt ?? this.portfolioValueUsdt,
      portfolioValueBtc: portfolioValueBtc ?? this.portfolioValueBtc,
      holdings: holdings ?? this.holdings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastRefresh: lastRefresh ?? this.lastRefresh,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PortfolioState &&
        other.portfolioValueUsdt == portfolioValueUsdt &&
        other.portfolioValueBtc == portfolioValueBtc &&
        listEquals(other.holdings, holdings) &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.lastRefresh == lastRefresh;
  }

  @override
  int get hashCode {
    return Object.hash(
      portfolioValueUsdt,
      portfolioValueBtc,
      Object.hashAll(holdings),
      isLoading,
      errorMessage,
      lastRefresh,
    );
  }
}