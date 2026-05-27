import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart' as loc;
import 'package:sabbh/core/data/cities_data.dart';
import 'package:sabbh/core/storage/shared_prefs_helper.dart';
import 'package:flutter/material.dart';
import 'package:sabbh/features/qibla/qibla_cubit.dart';
import 'package:sabbh/features/iqama_notification/iqama_notification_service.dart';

// ── State ────────────────────────────────────────────────────────

abstract class PrayerState {}

class PrayerInitial extends PrayerState {}

class PrayerLoading extends PrayerState {}

class PrayerLoaded extends PrayerState {
  final String locationName;
  final double lat;
  final double lng;
  final bool isGpsLocation;   // true = GPS, false = manual city / saved
  final DateTime selectedDate;
  final PrayerTimes times;
  final Prayer nextPrayer;
  final DateTime nextPrayerTime;
  final Map<String, int> adjustments;
  final String? noticeMessage;
  final int noticeId;

  PrayerLoaded({
    required this.locationName,
    required this.lat,
    required this.lng,
    this.isGpsLocation = false,
    required this.selectedDate,
    required this.times,
    required this.nextPrayer,
    required this.nextPrayerTime,
    required this.adjustments,
    this.noticeMessage,
    this.noticeId = 0,
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

  static const _keyLat    = 'prayer_lat';
  static const _keyLng    = 'prayer_lng';
  static const _keyName   = 'prayer_location_name';
  static const _keyIsGps  = 'prayer_is_gps';

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
  DateTime _selectedDate = _stripTime(DateTime.now());
  int _noticeCounter = 0;

  Map<String, int> get adjustments => Map.unmodifiable(_adjustments);
  DateTime get selectedDate => _selectedDate;

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
    final isGps = await prefs.getBool(_keyIsGps) ?? false;

    if (lat != null && lng != null && name != null) {
      _calculate(lat, lng, name, _selectedDate, isGpsLocation: isGps);
    }

    // محاولة التحديث الصامت للموقع في الخلفية (الاستراتيجية 1)
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
          );
          final cities = await CitiesRepository.load();
          CityEntry? closestCity;
          double minDistance = double.infinity;
          for (final city in cities) {
            final distance = Geolocator.distanceBetween(
              pos.latitude, pos.longitude, city.lat, city.lng,
            );
            if (distance < minDistance) {
              minDistance = distance;
              closestCity = city;
            }
          }
          final locName = closestCity != null ? 'موقعك الحالي: ${closestCity.city}' : 'موقعك الحالي';
          _calculate(pos.latitude, pos.longitude, locName, _selectedDate, isGpsLocation: true);
        }
      }
    } catch (_) {}
  }

  // ── Persist current location ───────────────────────────────────
  Future<void> _saveLocation(double lat, double lng, String name, {bool isGps = false}) async {
    final prefs = SharedPrefsHelper();
    await Future.wait([
      prefs.setDouble(_keyLat, lat),
      prefs.setDouble(_keyLng, lng),
      prefs.setString(_keyName, name),
      prefs.setBool(_keyIsGps, isGps),
    ]);
  }

  // ── Qibla Strict GPS Flow (الاستراتيجية 2) ─────────────────────
  Future<void> checkQiblaGps(BuildContext context, QiblaCubit qiblaCubit) async {
    try {
      // أولاً: فحص العتاد (هل الـ GPS شغال في الجهاز؟)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        qiblaCubit.setGpsNotice(GpsNotice(
          title: 'خدمة الموقع معطلة',
          message: 'يرجى تفعيل خدمة تحديد الموقع (GPS) لتعمل البوصلة بدقة.',
          actionLabel: 'تفعيل الموقع',
          colorValue: 0xFFE53935, // أحمر
          onAction: () async {
            loc.Location locationService = loc.Location();
            bool isEnabled = await locationService.requestService();
            if (isEnabled) {
              await Future.delayed(const Duration(milliseconds: 500));
              if (context.mounted) {
                checkQiblaGps(context, qiblaCubit);
              }
            }
          },
        ));
        return;
      }

      // ثانياً: فحص الإذن (Permission)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return; // المستخدم رفض الإذن
        }
      }

      if (permission == LocationPermission.deniedForever) {
        qiblaCubit.setGpsNotice(GpsNotice(
          title: 'الوصول الى الموقع',
          message: 'تم إيقاف الوصول الى الموقع. يرجى تفعيله من الإعدادات.',
          actionLabel: 'إعدادات التطبيق',
          colorValue: 0xFFF57C00, // برتقالي غامق
          onAction: () async => await Geolocator.openAppSettings(),
        ));
        return;
      }

      // ثانياً ب: فحص دقة الموقع (هل هو تقريبي أم دقيق؟)
      LocationAccuracyStatus accuracy = await Geolocator.getLocationAccuracy();
      if (accuracy == LocationAccuracyStatus.reduced) {
        qiblaCubit.setGpsNotice(GpsNotice(
          title: 'الموقع الدقيق مطلوب',
          message: 'لتحديد اتجاه القبلة بدقة، يحتاج التطبيق إلى إذن "الموقع الدقيق". ',
          actionLabel: 'تحسين الدقة',
          colorValue: 0xFFFFA726, // برتقالي فاتح
          onAction: () async {
            try {
              await Geolocator.requestPermission();
              final newAccuracy = await Geolocator.getLocationAccuracy();
              if (newAccuracy == LocationAccuracyStatus.reduced) {
                qiblaCubit.setGpsNotice(GpsNotice(
                  title: 'تحسين الدقة',
                  message: 'لم يتم الترقية. يمكنك تغييرها يدويًا من إعدادات التطبيق',
                  actionLabel: 'الإعدادات',
                  colorValue: 0xFFFFA726, // برتقالي فاتح
                  onAction: () async => await Geolocator.openAppSettings(),
                ));
              } else {
                if (context.mounted) {
                  checkQiblaGps(context, qiblaCubit);
                }
              }
            } catch (_) {}
          },
        ));
        return;
      }

      // إخفاء الإشعار في حال كان موجود وتم حل المشكلة
      qiblaCubit.clearGpsNotice();

      // ثالثاً: جلب الموقع الطازج بدقة عالية (Fresh Location)
      qiblaCubit.setLoading(true);

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // تمرير الموقع الطازج إلى QiblaCubit
      qiblaCubit.start(pos.latitude, pos.longitude);

      // تحديث مواقيت الصلاة في كامل التطبيق
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

      _calculate(pos.latitude, pos.longitude, locName, _selectedDate, isGpsLocation: true);

    } catch (e) {
      qiblaCubit.setError('تعذّر تحديد الموقع بدقة: $e');
    }
  }

  // ── GPS Flow ───────────────────────────────────────────────────
  Future<void> requestGPS() async {
    final previousLoaded = state is PrayerLoaded ? state as PrayerLoaded : null;
    if (previousLoaded == null) {
      emit(PrayerLoading());
    }
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _emitGpsError('خدمة الموقع غير مفعّلة', previousLoaded);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _emitGpsError('تم رفض إذن الموقع', previousLoaded);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _emitGpsError('تم حظر إذن الموقع نهائياً', previousLoaded);
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

      _calculate(pos.latitude, pos.longitude, locName, _selectedDate, isGpsLocation: true);
    } catch (e) {
      _emitGpsError('تعذّر تحديد الموقع: $e', previousLoaded);
    }
  }

  // ── City Selection Flow ────────────────────────────────────────
  void selectCity(CityEntry city) {
    emit(PrayerLoading());
    _calculate(city.lat, city.lng, city.displayName, _selectedDate, isGpsLocation: false);
  }

  // ── Recalculate with current location (after adjustment change) ─
  void _recalculate() {
    final s = state;
    if (s is PrayerLoaded) {
      _calculate(s.lat, s.lng, s.locationName, _selectedDate, isGpsLocation: s.isGpsLocation);
    }
  }

  void selectDate(DateTime date) {
    _selectedDate = _stripTime(date);
    final s = state;
    if (s is PrayerLoaded) {
      _calculate(s.lat, s.lng, s.locationName, _selectedDate, isGpsLocation: s.isGpsLocation);
    }
  }

  void goToNextDay() => selectDate(_selectedDate.add(const Duration(days: 1)));

  void goToPreviousDay() => selectDate(_selectedDate.subtract(const Duration(days: 1)));

  // ── Core Calculation ───────────────────────────────────────────
  void _calculate(double lat, double lng, String name, DateTime selectedDate,
      {bool isGpsLocation = false}) {
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

      final date    = DateComponents.from(selectedDate);
      final times   = PrayerTimes(coords, date, params);

      final nowRef = _referenceNowForSelectedDate(selectedDate);
      final next = _nextPrayerFor(times, nowRef);
      final nextTime = times.timeForPrayer(next) ?? nowRef;

      emit(PrayerLoaded(
        locationName: name,
        lat: lat,
        lng: lng,
        isGpsLocation: isGpsLocation,
        selectedDate: selectedDate,
        times: times,
        nextPrayer: next,
        nextPrayerTime: nextTime,
        adjustments: Map.from(_adjustments),
        noticeMessage: null,
        noticeId: 0,
      ));

      _saveLocation(lat, lng, name, isGps: isGpsLocation);
      // Keep notification sync tied to real "today" only.
      if (_isSameDay(selectedDate, DateTime.now())) {
        IqamaNotificationService.instance.syncPrayerTimes(
          times: times,
          locationName: name,
        );
      }
    } catch (e) {
      emit(PrayerError('خطأ في حساب مواقيت الصلاة: $e'));
    }
  }

  static DateTime _stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _referenceNowForSelectedDate(DateTime selectedDate) {
    final now = DateTime.now();
    if (_isSameDay(selectedDate, now)) return now;
    return DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  }

  Prayer _nextPrayerFor(PrayerTimes times, DateTime nowRef) {
    final schedule = <Prayer, DateTime>{
      Prayer.fajr: times.fajr,
      Prayer.sunrise: times.sunrise,
      Prayer.dhuhr: times.dhuhr,
      Prayer.asr: times.asr,
      Prayer.maghrib: times.maghrib,
      Prayer.isha: times.isha,
    };
    for (final entry in schedule.entries) {
      if (entry.value.isAfter(nowRef)) return entry.key;
    }
    return Prayer.fajr;
  }

  void _emitGpsError(String message, PrayerLoaded? previousLoaded) {
    if (previousLoaded != null) {
      _noticeCounter++;
      emit(PrayerLoaded(
        locationName: previousLoaded.locationName,
        lat: previousLoaded.lat,
        lng: previousLoaded.lng,
        isGpsLocation: previousLoaded.isGpsLocation,
        selectedDate: previousLoaded.selectedDate,
        times: previousLoaded.times,
        nextPrayer: previousLoaded.nextPrayer,
        nextPrayerTime: previousLoaded.nextPrayerTime,
        adjustments: previousLoaded.adjustments,
        noticeMessage: message,
        noticeId: _noticeCounter,
      ));
      return;
    }
    emit(PrayerError(message));
  }

  void clearNotice(int noticeId) {
    final s = state;
    if (s is! PrayerLoaded) return;
    if (s.noticeMessage == null || s.noticeId != noticeId) return;
    emit(PrayerLoaded(
      locationName: s.locationName,
      lat: s.lat,
      lng: s.lng,
      isGpsLocation: s.isGpsLocation,
      selectedDate: s.selectedDate,
      times: s.times,
      nextPrayer: s.nextPrayer,
      nextPrayerTime: s.nextPrayerTime,
      adjustments: s.adjustments,
      noticeMessage: null,
      noticeId: 0,
    ));
  }
}
