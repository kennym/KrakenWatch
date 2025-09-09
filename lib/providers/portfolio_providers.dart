import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../services/portfolio_service.dart';
import '../services/kraken_api_service.dart';
import '../models/portfolio_state.dart';

// Service provider
final portfolioServiceProvider = Provider<PortfolioService>((ref) {
  return KrakenApiService(
    apiKey: ApiConfig.krakenApiKey,
    apiSecret: ApiConfig.krakenApiSecret,
  );
});

// Privacy mode provider
final privacyModeProvider = StateProvider<bool>((ref) => true);

// Portfolio state provider
final portfolioProvider = StateNotifierProvider<PortfolioNotifier, PortfolioState>((ref) {
  final service = ref.watch(portfolioServiceProvider);
  return PortfolioNotifier(service);
});

class PortfolioNotifier extends StateNotifier<PortfolioState> {
  final PortfolioService _portfolioService;

  PortfolioNotifier(this._portfolioService) : super(const PortfolioState()) {
    // Auto-load portfolio on initialization
    loadPortfolio();
  }

  Future<void> loadPortfolio() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final portfolioState = await _portfolioService.getPortfolio();
      state = portfolioState;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load portfolio: ${e.toString()}',
      );
    }
  }

  Future<void> refreshPortfolio() async {
    await loadPortfolio();
  }
}