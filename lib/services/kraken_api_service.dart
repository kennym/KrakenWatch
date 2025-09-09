import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/balance.dart';
import '../models/portfolio_state.dart';
import 'portfolio_service.dart';
import 'calculation_service.dart';

class KrakenApiService implements PortfolioService {
  static const String _baseUrl = 'https://api.kraken.com';
  
  final String _apiKey;
  final String _apiSecret;

  KrakenApiService({
    required String apiKey,
    required String apiSecret,
  }) : _apiKey = apiKey, _apiSecret = apiSecret;

  @override
  Future<PortfolioState> getPortfolio() async {
    try {
      // Fetch both balance and market prices
      final balance = await getBalance();
      final prices = await getPrices();
      
      if (balance.error.isNotEmpty) {
        return PortfolioState(
          isLoading: false,
          errorMessage: 'Kraken API Error: ${balance.error.join(', ')}',
        );
      }
      
      // Calculate total portfolio value and individual holdings
      final portfolioValueUsd = CalculationService.calculatePortfolioValueInUsd(balance.result, prices);
      final portfolioValueBtc = CalculationService.convertUsdToBtc(portfolioValueUsd, prices);
      final holdings = CalculationService.calculatePortfolioHoldings(balance.result, prices);
      
      return PortfolioState(
        portfolioValueUsdt: portfolioValueUsd,
        portfolioValueBtc: portfolioValueBtc,
        holdings: holdings,
        isLoading: false,
        lastRefresh: DateTime.now(),
      );
    } catch (e) {
      return PortfolioState(
        isLoading: false,
        errorMessage: 'Failed to load portfolio: ${e.toString()}',
      );
    }
  }

  @override
  Future<Map<String, double>> getPrices() async {
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

  @override
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
}