import '../models/balance.dart';
import '../models/portfolio_state.dart';

abstract class PortfolioService {
  Future<PortfolioState> getPortfolio();
  Future<KrakenBalance> getBalance();
  Future<Map<String, double>> getPrices();
}