// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'balance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KrakenBalance _$KrakenBalanceFromJson(Map<String, dynamic> json) =>
    KrakenBalance(
      result: Map<String, String>.from(json['result'] as Map),
      error: (json['error'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$KrakenBalanceToJson(KrakenBalance instance) =>
    <String, dynamic>{'result': instance.result, 'error': instance.error};
