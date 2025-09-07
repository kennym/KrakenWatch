import 'package:json_annotation/json_annotation.dart';

part 'balance.g.dart';

@JsonSerializable()
class KrakenBalance {
  final Map<String, String> result;
  final List<String> error;

  KrakenBalance({
    required this.result,
    required this.error,
  });

  factory KrakenBalance.fromJson(Map<String, dynamic> json) =>
      _$KrakenBalanceFromJson(json);

  Map<String, dynamic> toJson() => _$KrakenBalanceToJson(this);
}