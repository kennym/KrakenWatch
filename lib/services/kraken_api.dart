import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/balance.dart';

class KrakenApi {
  static const String _baseUrl = 'https://api.kraken.com';
  
  final String _apiKey;
  final String _apiSecret;

  KrakenApi({
    required String apiKey,
    required String apiSecret,
  }) : _apiKey = apiKey, _apiSecret = apiSecret;

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
    total += parseBalance(balances, 'ZUSDT');
    total += parseBalance(balances, 'ZUSD');
    return total;
  }

  double calculateTotalInBtc(Map<String, String> balances) {
    double total = 0.0;
    total += parseBalance(balances, 'XXBT');
    total += parseBalance(balances, 'XBT');
    return total;
  }
}