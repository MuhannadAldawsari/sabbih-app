import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sabbh/core/data/cities_data.dart';
import 'package:sabbh/core/storage/shared_prefs_helper.dart';
import 'package:sabbh/features/iqama_notification/iqama_notification_service.dart';

// ── State ────────────────────────────────────────────────────────

abstract class PrayerState {}

class PrayerInitial extends PrayerState {}

class PrayerLoading extends PrayerState {}

class PrayerLoaded extends PrayerState {
  final String locationName;
  final double lat;
  final double lng;
  final PrayerTimes times;
  final Prayer nextPrayer;
  final DateTime nextPrayerTime;
  final Map<String, int> adjustments;

  PrayerLoaded({
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.times,
    required this.nextPrayer,
    required this.nextPrayerTime,
    required this.adjustments,
  });
}

class PrayerError extends PrayerState {
  final String message;
  PrayerError(this.message);
}

// ── Cubit ────────────────────────────────────────────────────────

class PrayerCubit extends Cubit<PrayerState> {
  PrayerCubit() : super(PrayerInitial()) {
    _loadSavedLocation();
  }

  static const _keyLat  = 'prayer_lat';
  static const _keyLng  = 'prayer_lng';
  static const _keyName = 'prayer_location_name';

  static const prayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
  static const prayerLabels = {
    'fajr': 'الفجر',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  final Map<String, int> _adjustments = {
    'fajr': 0, 'dhuhr': 0, 'asr': 0, 'maghrib': 0, 'isha': 0,
  };

  Map<String, int> get adjustments => Map.unmodifiable(_adjustments);

  // ── Adjustments ────────────────────────────────────────────────

  Future<void> _loadAdjustments() async {
    final prefs = SharedPrefsHelper();
    for (final key in prayerKeys) {
      _adjustments[key] = await prefs.getInt('adj_$key') ?? 0;
    }
  }

  Future<void> setAdjustment(String prayerKey, int minutes) async {
    _adjustments[prayerKey] = minutes;
    await SharedPrefsHelper().setInt('adj_$prayerKey', minutes);
    _recalculate();
  }

  // ── Restore last saved location on startup ─────────────────────
  Future<void> _loadSavedLocation() async {
    await _loadAdjustments();
    final prefs = SharedPrefsHelper();
    final lat  = await prefs.getDouble(_keyLat);
    final lng  = await prefs.getDouble(_keyLng);
    final name = await prefs.getString(_keyName);
    if (lat != null && lng != null && name != null) {
      _calculate(lat, lng, name);
    }
  }

  // ── Persist current location ───────────────────────────────────
  Future<void> _saveLocation(double lat, double lng, String name) async {
    final prefs = SharedPrefsHelper();
    await Future.wait([
      prefs.setDouble(_keyLat, lat),
      prefs.setDouble(_keyLng, lng),
      prefs.setString(_keyName, name),
    ]);
  }

  // ── GPS Flow ───────────────────────────────────────────────────
  Future<void> requestGPS() async {
    emit(PrayerLoading());
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(PrayerError('خدمة الموقع غير مفعّلة'));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(PrayerError('تم رفض إذن الموقع'));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        emit(PrayerError('تم حظر إذن الموقع نهائياً'));
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      final cities = await CitiesRepository.load();
      CityEntry? closestCity;
      double minDistance = double.infinity;

      for (final city in cities) {
        final distance = Geolocator.distanceBetween(
          pos.latitude, pos.longitude,
          city.lat, city.lng,
        );
        if (distance < minDistance) {
          minDistance = distance;
          closestCity = city;
        }
      }

      final locName = closestCity != null
          ? 'موقعك الحالي: ${closestCity.city}'
          : 'موقعك الحالي';

      _calculate(pos.latitude, pos.longitude, locName);
    } catch (e) {
      emit(PrayerError('تعذّر تحديد الموقع: $e'));
    }
  }

  // ── City Selection Flow ────────────────────────────────────────
  void selectCity(CityEntry city) {
    emit(PrayerLoading());
    _calculate(city.lat, city.lng, city.displayName);
  }

  // ── Recalculate with current location (after adjustment change) ─
  void _recalculate() {
    final s = state;
    if (s is PrayerLoaded) {
      _calculate(s.lat, s.lng, s.locationName);
    }
  }

  // ── Core Calculation ───────────────────────────────────────────
  void _calculate(double lat, double lng, String name) {
    try {
      final coords = Coordinates(lat, lng);
      final params  = CalculationMethod.umm_al_qura.getParameters();

      params.adjustments = PrayerAdjustments(
        fajr:    _adjustments['fajr']    ?? 0,
        dhuhr:   _adjustments['dhuhr']   ?? 0,
        asr:     _adjustments['asr']     ?? 0,
        maghrib: _adjustments['maghrib'] ?? 0,
        isha:    _adjustments['isha']    ?? 0,
      );

      final date    = DateComponents.from(DateTime.now());
      final times   = PrayerTimes(coords, date, params);

      final next     = times.nextPrayer();
      final nextTime = times.timeForPrayer(next) ?? DateTime.now();

      emit(PrayerLoaded(
        locationName: name,
        lat: lat,
        lng: lng,
        times: times,
        nextPrayer: next,
        nextPrayerTime: nextTime,
        adjustments: Map.from(_adjustments),
      ));

      _saveLocation(lat, lng, name);
      IqamaNotificationService.instance.syncPrayerTimes(
        times: times,
        locationName: name,
      );
    } catch (e) {
      emit(PrayerError('خطأ في حساب مواقيت الصلاة: $e'));
    }
  }
}
