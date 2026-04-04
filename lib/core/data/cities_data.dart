import 'dart:convert';
import 'package:flutter/services.dart';

class CityEntry {
  final String country;
  final String city;
  final double lat;
  final double lng;

  const CityEntry({
    required this.country,
    required this.city,
    required this.lat,
    required this.lng,
  });

  factory CityEntry.fromJson(Map<String, dynamic> j) => CityEntry(
        country: j['country'] as String,
        city:    j['city']    as String,
        lat:     (j['lat'] as num).toDouble(),
        lng:     (j['lng'] as num).toDouble(),
      );

  String get displayName => '$city، $country';
}

class CitiesRepository {
  static List<CityEntry>? _cache;

  static Future<List<CityEntry>> load() async {
    if (_cache != null) return _cache!;
    final raw  = await rootBundle.loadString('assets/cities.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list.map((e) => CityEntry.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
  }
}
