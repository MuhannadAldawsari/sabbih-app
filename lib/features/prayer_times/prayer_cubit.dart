import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sabbh/core/data/cities_data.dart';

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

  PrayerLoaded({
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.times,
    required this.nextPrayer,
    required this.nextPrayerTime,
  });
}

class PrayerError extends PrayerState {
  final String message;
  PrayerError(this.message);
}

// ── Cubit ────────────────────────────────────────────────────────

class PrayerCubit extends Cubit<PrayerState> {
  PrayerCubit() : super(PrayerInitial());

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

      // Find closest city from our JSON to display its name
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

  // ── Core Calculation ───────────────────────────────────────────
  void _calculate(double lat, double lng, String name) {
    try {
      final coords = Coordinates(lat, lng);
      final params  = CalculationMethod.umm_al_qura.getParameters();
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
      ));
    } catch (e) {
      emit(PrayerError('خطأ في حساب مواقيت الصلاة: $e'));
    }
  }
}
