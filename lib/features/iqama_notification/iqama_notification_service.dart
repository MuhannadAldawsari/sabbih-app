import 'dart:io';
import 'dart:typed_data';

import 'package:adhan/adhan.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sabbh/core/resources/colores.dart';
import 'package:sabbh/core/storage/shared_prefs_helper.dart';
import 'package:sabbh/features/iqama_notification/iqama_countdown_logic.dart';

const _kIqamaNotifEnabled = 'iqama_notif_enabled';
const _kIqamaNotifMode = 'iqama_notif_mode';
const _kIqamaNotifIsDark = 'iqama_notif_is_dark';
const _kIqamaNotifLocationName = 'iqama_notif_location_name';
const _kIqamaNotifFajr = 'iqama_notif_fajr';
const _kIqamaNotifDhuhr = 'iqama_notif_dhuhr';
const _kIqamaNotifAsr = 'iqama_notif_asr';
const _kIqamaNotifMaghrib = 'iqama_notif_maghrib';
const _kIqamaNotifIsha = 'iqama_notif_isha';
const _kIqamaNotifSunrise = 'iqama_notif_sunrise';

const _kNotifChannelId = 'sabbh_iqama_persistent';
const _kNotifChannelName = 'عداد الأذان والإقامة';
const _kNotifChannelDescription = 'إشعار حي للوقت المتبقي للأذان ووقت الإقامة';
const _kNotifId = 808;
const _kAndroidNotificationFlagNoClear = 32;
const _kShowAlarmBaseId = 1200;
const _kMidnightAlarmId = 3000;
const _kAlarmRevision = 'iqama_alarm_revision';
const _kIqamaNotifModeSchemaV2 = 'iqama_notif_mode_schema_v2';
const _kLegacyIqamaNotifModeCamel = 'iqamaNotifMode';
const _kExactAlarmBlocked = 'iqama_exact_alarm_blocked';

const _kMorningAdhkarEnabled = 'morning_adhkar_enabled';
const _kMorningAdhkarSound = 'morning_adhkar_sound';
const _kMorningAdhkarHour = 'morning_adhkar_hour';
const _kMorningAdhkarMinute = 'morning_adhkar_minute';

const _kEveningAdhkarEnabled = 'evening_adhkar_enabled';
const _kEveningAdhkarSound = 'evening_adhkar_sound';
const _kEveningAdhkarHour = 'evening_adhkar_hour';
const _kEveningAdhkarMinute = 'evening_adhkar_minute';

const _kMorningAdhkarAlarmId = 4000;
const _kEveningAdhkarAlarmId = 4001;

const _kAdhkarMorningChannelId = 'adhkar_morning_channel_id_v4';
const _kAdhkarMorningSilentChannelId = 'adhkar_morning_silent_channel_id_v4';
const _kAdhkarEveningChannelId = 'adhkar_evening_channel_id_v4';
const _kAdhkarEveningSilentChannelId = 'adhkar_evening_silent_channel_id_v4';


class IqamaNotificationService {
  IqamaNotificationService._();
  static final instance = IqamaNotificationService._();
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// ترحيل لمرة واحدة من فهرس الوضع القديم (4 قيم) إلى الجديد (3 قيم).
  static Future<void> ensureModePrefsMigrated() async {
    final prefs = SharedPrefsHelper();
    if (await prefs.getBool(_kIqamaNotifModeSchemaV2) ?? false) return;
    final raw = await prefs.getInt(_kIqamaNotifMode) ??
        await prefs.getInt(_kLegacyIqamaNotifModeCamel);
    final idx = migrateLegacyIqamaNotifModeIndex(raw);
    await prefs.setInt(_kIqamaNotifMode, idx);
    await prefs.setInt(_kLegacyIqamaNotifModeCamel, idx);
    await prefs.setBool(_kIqamaNotifModeSchemaV2, true);
  }

  Future<void> ensureAndroidNotificationPermission() async {
    if (!Platform.isAndroid) return;
    final status = await Permission.notification.status;
    if (status.isGranted || status.isLimited) return;

    final android = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final fromPlugin = await android?.requestNotificationsPermission();
    if (fromPlugin == true) return;

    await Permission.notification.request();
  }

  Future<bool> ensureExactAlarmPermission({bool requestIfNeeded = false}) async {
    if (!Platform.isAndroid) return true;
    final prefs = SharedPrefsHelper();
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) {
      await prefs.setBool(_kExactAlarmBlocked, false);
      return true;
    }

    debugPrint(
      'IqamaNotificationService: exact alarms are not allowed; notifications may be delayed until user unlocks device.',
    );
    if (requestIfNeeded) {
      await Permission.scheduleExactAlarm.request();
      final afterRequest = await Permission.scheduleExactAlarm.status;
      if (afterRequest.isGranted) {
        await prefs.setBool(_kExactAlarmBlocked, false);
        return true;
      }
    }
    await prefs.setBool(_kExactAlarmBlocked, true);
    return false;
  }

  Future<bool> isExactAlarmPermissionBlocked() async {
    return await SharedPrefsHelper().getBool(_kExactAlarmBlocked) ?? false;
  }

  Future<void> init() async {
    if (!Platform.isAndroid) return;

    const androidSettings = AndroidInitializationSettings('ic_notification');
    await _notifications.initialize(
      const InitializationSettings(android: androidSettings),
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // ── Clean Up Old Channels ──
    final channels = await androidPlugin?.getNotificationChannels();
    if (channels != null) {
      for (final channel in channels) {
        if (channel.id != _kNotifChannelId &&
            channel.id != _kAdhkarMorningChannelId &&
            channel.id != _kAdhkarMorningSilentChannelId &&
            channel.id != _kAdhkarEveningChannelId &&
            channel.id != _kAdhkarEveningSilentChannelId) {
          await androidPlugin?.deleteNotificationChannel(channel.id);
        }
      }
    }

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kNotifChannelId,
        _kNotifChannelName,
        description: _kNotifChannelDescription,
        importance: Importance.defaultImportance,
        playSound: false,
        enableVibration: false,
      ),
    );

    // ── Adhkar Channels ──
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kAdhkarMorningChannelId,
        'أذكار الصباح (بصوت)',
        description: 'تنبيهات لقراءة أذكار الصباح مع تشغيل الصوت المخصص',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('morning'),
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kAdhkarMorningSilentChannelId,
        'أذكار الصباح (صامت)',
        description: 'تنبيهات لقراءة أذكار الصباح تظهر كإشعار صامت فقط',
        importance: Importance.max,
        playSound: false,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kAdhkarEveningChannelId,
        'أذكار المساء (بصوت)',
        description: 'تنبيهات لقراءة أذكار المساء مع تشغيل الصوت المخصص',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('evening'),
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kAdhkarEveningSilentChannelId,
        'أذكار المساء (صامت)',
        description: 'تنبيهات لقراءة أذكار المساء تظهر كإشعار صامت فقط',
        importance: Importance.max,
        playSound: false,
      ),
    );
  }

  Future<void> restoreFromPrefsAndStartIfNeeded() async {
    if (!Platform.isAndroid) return;
    final prefs = SharedPrefsHelper();
    final enabled = await prefs.getBool(_kIqamaNotifEnabled) ?? false;
    if (!enabled) return;
    final exactAllowed = await ensureExactAlarmPermission();
    if (!exactAllowed) return;
    final mode = await _getMode();
    await _scheduleWindowModeAlarms(mode);
    await scheduleAdhkarAlarms();
  }

  Future<void> updateThemeMode(bool isDark) async {
    if (!Platform.isAndroid) return;
    await SharedPrefsHelper().setBool(_kIqamaNotifIsDark, isDark);
  }

  Future<void> syncPrayerTimes({
    required PrayerTimes times,
    required String locationName,
  }) async {
    if (!Platform.isAndroid) return;

    final prefs = SharedPrefsHelper();
    await Future.wait([
      prefs.setString(_kIqamaNotifLocationName, locationName),
      prefs.setInt(_kIqamaNotifFajr, times.fajr.millisecondsSinceEpoch),
      prefs.setInt(_kIqamaNotifDhuhr, times.dhuhr.millisecondsSinceEpoch),
      prefs.setInt(_kIqamaNotifAsr, times.asr.millisecondsSinceEpoch),
      prefs.setInt(_kIqamaNotifMaghrib, times.maghrib.millisecondsSinceEpoch),
      prefs.setInt(_kIqamaNotifIsha, times.isha.millisecondsSinceEpoch),
      prefs.setInt(_kIqamaNotifSunrise, times.sunrise.millisecondsSinceEpoch),
    ]);
    final enabled = await prefs.getBool(_kIqamaNotifEnabled) ?? false;
    if (!enabled) return;
    final exactAllowed = await ensureExactAlarmPermission();
    if (!exactAllowed) return;

    final mode = await _getMode();
    await _scheduleWindowModeAlarms(mode);
  }

  Future<void> applySettings({
    required bool enabled,
    required IqamaNotifMode mode,
  }) async {
    if (!Platform.isAndroid) return;

    final prefs = SharedPrefsHelper();
    await Future.wait([
      prefs.setBool(_kIqamaNotifEnabled, enabled),
      prefs.setInt(_kIqamaNotifMode, mode.index),
    ]);

    if (enabled) {
      final exactAllowed = await ensureExactAlarmPermission();
      if (!exactAllowed) {
        await _bumpAlarmRevision();
        await _cancelAllWindowAlarms();
        await AndroidAlarmManager.cancel(_kMidnightAlarmId);
        await stop();
        return;
      }
      await _scheduleWindowModeAlarms(mode);
    } else {
      await _bumpAlarmRevision();
      await _cancelAllWindowAlarms();
      await AndroidAlarmManager.cancel(_kMidnightAlarmId);
      await stop();
    }
  }

  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    await _notifications.cancel(_kNotifId);
  }

  Future<IqamaNotifMode> _getMode() async {
    await ensureModePrefsMigrated();
    final prefs = SharedPrefsHelper();
    final idx =
        await prefs.getInt(_kIqamaNotifMode) ?? IqamaNotifMode.before45.index;
    return IqamaNotifMode.values[idx.clamp(0, IqamaNotifMode.values.length - 1)];
  }

  Future<void> _showChronometerNotification({
    required String prayerName,
    required String location,
    required DateTime targetTime,
    required int timeoutAfterMs,
  }) async {
    final content = _buildNotificationContent(
      prayerName: prayerName,
      location: location,
      adhanLocalTime: targetTime,
    );
    final isDark = await _resolveDarkThemeForNotification();
    await _notifications.show(
      _kNotifId,
      content.title,
      content.body,
      NotificationDetails(
        android: _androidChronometerDetails(
          isDarkTheme: isDark,
          whenMillis: targetTime.millisecondsSinceEpoch,
          bigText: content.bigText,
          timeoutAfterMs: timeoutAfterMs,
        ),
      ),
    );
  }

  Future<bool> _resolveDarkThemeForNotification() async {
    final prefs = SharedPrefsHelper();
    final stored = await prefs.getBool(_kIqamaNotifIsDark);
    if (stored != null) return stored;
    return await prefs.getBool('isDarkMode') ?? false;
  }

  AndroidNotificationDetails _androidChronometerDetails({
    required bool isDarkTheme,
    required int whenMillis,
    required String bigText,
    required int timeoutAfterMs,
  }) {
    final background = ColorsManager.iqamaNotifAdhanBackgroundDark;
    return AndroidNotificationDetails(
      _kNotifChannelId,
      _kNotifChannelName,
      channelDescription: _kNotifChannelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(bigText),
      ongoing: true,
      autoCancel: false,
      silent: true,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      showWhen: true,
      when: whenMillis,
      usesChronometer: true,
      chronometerCountDown: true,
      colorized: true,
      color: background,
      category: AndroidNotificationCategory.service,
      visibility: NotificationVisibility.public,
      additionalFlags: Int32List.fromList(const [_kAndroidNotificationFlagNoClear]),
      timeoutAfter: timeoutAfterMs,
    );
  }

  Future<void> _scheduleWindowModeAlarms(IqamaNotifMode mode) async {
    await _notifications.cancel(_kNotifId);
    await _cancelAllWindowAlarms();
    final prefs = SharedPrefsHelper();
    final revision = await _bumpAlarmRevision();
    final fajr = await prefs.getInt(_kIqamaNotifFajr);
    final dhuhr = await prefs.getInt(_kIqamaNotifDhuhr);
    final asr = await prefs.getInt(_kIqamaNotifAsr);
    final maghrib = await prefs.getInt(_kIqamaNotifMaghrib);
    final isha = await prefs.getInt(_kIqamaNotifIsha);
    final sunrise = await prefs.getInt(_kIqamaNotifSunrise);
    if (fajr == null || sunrise == null || dhuhr == null || asr == null || maghrib == null || isha == null) return;

    final schedule = <Prayer, DateTime>{
      Prayer.fajr: DateTime.fromMillisecondsSinceEpoch(fajr),
      Prayer.sunrise: DateTime.fromMillisecondsSinceEpoch(sunrise),
      Prayer.dhuhr: DateTime.fromMillisecondsSinceEpoch(dhuhr),
      Prayer.asr: DateTime.fromMillisecondsSinceEpoch(asr),
      Prayer.maghrib: DateTime.fromMillisecondsSinceEpoch(maghrib),
      Prayer.isha: DateTime.fromMillisecondsSinceEpoch(isha),
    };
    final userMinutes = switch (mode) {
      IqamaNotifMode.before45 => 45,
      IqamaNotifMode.before30 => 30,
      IqamaNotifMode.before15 => 15,
    };

    final now = DateTime.now();
    var index = 0;
    for (final prayer in [Prayer.fajr, Prayer.sunrise, Prayer.dhuhr, Prayer.asr, Prayer.maghrib, Prayer.isha]) {
      final adhanTime = schedule[prayer]!;
      final showTime = adhanTime.subtract(Duration(minutes: userMinutes));
      final hideTime = adhanTime.add(const Duration(minutes: 30));

      if (hideTime.isBefore(now)) {
        index++;
        continue;
      }

      final showId = _kShowAlarmBaseId + index;

      await prefs.setInt('iqama_alarm_show_adhan_$showId', adhanTime.millisecondsSinceEpoch);
      await prefs.setString(
        'iqama_alarm_show_prayer_$showId',
        _prayerName(prayer, adhanTime),
      );
      await prefs.setInt('iqama_alarm_show_at_$showId', showTime.millisecondsSinceEpoch);
      await prefs.setInt('iqama_alarm_hide_at_$showId', hideTime.millisecondsSinceEpoch);
      await prefs.setInt('iqama_alarm_revision_$showId', revision);

      if (showTime.isAfter(now)) {
        await AndroidAlarmManager.oneShotAt(
          showTime,
          showId,
          _showAlarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          allowWhileIdle: true,
        );
      } else if (hideTime.isAfter(now)) {
        // If settings are enabled while already inside the active window,
        // show immediately (covers both pre-adhan and post-adhan window).
        await _showFromAlarmId(showId);
      }

      index++;
    }

    await _scheduleMidnightAlarm();
  }

  Future<void> _cancelAllWindowAlarms() async {
    for (var i = 0; i < 6; i++) {
      await AndroidAlarmManager.cancel(_kShowAlarmBaseId + i);
    }
  }

  Future<void> _showFromAlarmId(int id) async {
    final prefs = SharedPrefsHelper();
    final enabled = await prefs.getBool(_kIqamaNotifEnabled) ?? false;
    if (!enabled) return;
    final currentRevision = await prefs.getInt(_kAlarmRevision) ?? 0;
    final alarmRevision = await prefs.getInt('iqama_alarm_revision_$id') ?? -1;
    if (currentRevision != alarmRevision) return;

    final adhanMillis = await prefs.getInt('iqama_alarm_show_adhan_$id');
    final prayerName = await prefs.getString('iqama_alarm_show_prayer_$id');
    final showAtMillis = await prefs.getInt('iqama_alarm_show_at_$id');
    final hideAtMillis = await prefs.getInt('iqama_alarm_hide_at_$id');
    final location = await prefs.getString(_kIqamaNotifLocationName) ?? 'مواقيت الصلاة';
    if (adhanMillis == null || prayerName == null || showAtMillis == null || hideAtMillis == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now < showAtMillis || now >= hideAtMillis) return;

    final remainingMs = hideAtMillis - now;
    if (remainingMs <= 0) return;

    await _showChronometerNotification(
      prayerName: prayerName,
      location: location,
      targetTime: DateTime.fromMillisecondsSinceEpoch(adhanMillis),
      timeoutAfterMs: remainingMs,
    );
  }

  Future<void> _scheduleMidnightAlarm() async {
    await AndroidAlarmManager.cancel(_kMidnightAlarmId);
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 5);
    await AndroidAlarmManager.oneShotAt(
      nextMidnight,
      _kMidnightAlarmId,
      _midnightRescheduleCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
    );
  }

  Future<void> _recalculateAndReschedule() async {
    final prefs = SharedPrefsHelper();
    final enabled = await prefs.getBool(_kIqamaNotifEnabled) ?? false;
    if (!enabled) return;

    final lat = await prefs.getDouble('prayer_lat');
    final lng = await prefs.getDouble('prayer_lng');
    if (lat == null || lng == null) return;

    final adjFajr = await prefs.getInt('adj_fajr') ?? 0;
    final adjDhuhr = await prefs.getInt('adj_dhuhr') ?? 0;
    final adjAsr = await prefs.getInt('adj_asr') ?? 0;
    final adjMaghrib = await prefs.getInt('adj_maghrib') ?? 0;
    final adjIsha = await prefs.getInt('adj_isha') ?? 0;

    final coords = Coordinates(lat, lng);
    final params = CalculationMethod.umm_al_qura.getParameters();
    params.adjustments = PrayerAdjustments(
      fajr: adjFajr,
      dhuhr: adjDhuhr,
      asr: adjAsr,
      maghrib: adjMaghrib,
      isha: adjIsha,
    );

    final date = DateComponents.from(DateTime.now());
    final times = PrayerTimes(coords, date, params);
    await Future.wait([
      prefs.setInt(_kIqamaNotifFajr, times.fajr.millisecondsSinceEpoch),
      prefs.setInt(_kIqamaNotifDhuhr, times.dhuhr.millisecondsSinceEpoch),
      prefs.setInt(_kIqamaNotifAsr, times.asr.millisecondsSinceEpoch),
      prefs.setInt(_kIqamaNotifMaghrib, times.maghrib.millisecondsSinceEpoch),
      prefs.setInt(_kIqamaNotifIsha, times.isha.millisecondsSinceEpoch),
      prefs.setInt(_kIqamaNotifSunrise, times.sunrise.millisecondsSinceEpoch),
    ]);

    final mode = await _getMode();
    await _scheduleWindowModeAlarms(mode);
  }

  Future<int> _bumpAlarmRevision() async {
    final prefs = SharedPrefsHelper();
    final current = await prefs.getInt(_kAlarmRevision) ?? 0;
    final next = current + 1;
    await prefs.setInt(_kAlarmRevision, next);
    return next;
  }

  // ── Adhkar Logic ────────────────────────────────────────────────

  Future<void> updateAdhkarSettings({
    required bool morningEnabled,
    required bool morningSound,
    required TimeOfDay morningTime,
    required bool eveningEnabled,
    required bool eveningSound,
    required TimeOfDay eveningTime,
  }) async {
    final prefs = SharedPrefsHelper();
    await Future.wait([
      prefs.setBool(_kMorningAdhkarEnabled, morningEnabled),
      prefs.setBool(_kMorningAdhkarSound, morningSound),
      prefs.setInt(_kMorningAdhkarHour, morningTime.hour),
      prefs.setInt(_kMorningAdhkarMinute, morningTime.minute),

      prefs.setBool(_kEveningAdhkarEnabled, eveningEnabled),
      prefs.setBool(_kEveningAdhkarSound, eveningSound),
      prefs.setInt(_kEveningAdhkarHour, eveningTime.hour),
      prefs.setInt(_kEveningAdhkarMinute, eveningTime.minute),
    ]);

    await scheduleAdhkarAlarms();
  }

  Future<void> scheduleAdhkarAlarms() async {
    final prefs = SharedPrefsHelper();
    final morningEnabled = await prefs.getBool(_kMorningAdhkarEnabled) ?? true;
    final morningHour = await prefs.getInt(_kMorningAdhkarHour) ?? 5;
    final morningMinute = await prefs.getInt(_kMorningAdhkarMinute) ?? 0;
    
    final eveningEnabled = await prefs.getBool(_kEveningAdhkarEnabled) ?? true;
    final eveningHour = await prefs.getInt(_kEveningAdhkarHour) ?? 16;
    final eveningMinute = await prefs.getInt(_kEveningAdhkarMinute) ?? 0;

    await AndroidAlarmManager.cancel(_kMorningAdhkarAlarmId);
    if (morningEnabled) {
      final now = DateTime.now();
      var morningTime = DateTime(now.year, now.month, now.day, morningHour, morningMinute);
      if (morningTime.isBefore(now)) {
        morningTime = morningTime.add(const Duration(days: 1));
      }
      await AndroidAlarmManager.oneShotAt(
        morningTime,
        _kMorningAdhkarAlarmId,
        _morningAdhkarCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
      );
    }

    await AndroidAlarmManager.cancel(_kEveningAdhkarAlarmId);
    if (eveningEnabled) {
      final now = DateTime.now();
      var eveningTime = DateTime(now.year, now.month, now.day, eveningHour, eveningMinute);
      if (eveningTime.isBefore(now)) {
        eveningTime = eveningTime.add(const Duration(days: 1));
      }
      await AndroidAlarmManager.oneShotAt(
        eveningTime,
        _kEveningAdhkarAlarmId,
        _eveningAdhkarCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
      );
    }
  }

  Future<void> showAdhkarNotification({required bool isMorning}) async {
    final prefs = SharedPrefsHelper();
    final withSound = isMorning
        ? (await prefs.getBool(_kMorningAdhkarSound) ?? true)
        : (await prefs.getBool(_kEveningAdhkarSound) ?? true);

    String channelId;
    String channelName;
    if (isMorning) {
      channelId = withSound ? _kAdhkarMorningChannelId : _kAdhkarMorningSilentChannelId;
      channelName = withSound ? 'أذكار الصباح (بصوت)' : 'أذكار الصباح (صامت)';
    } else {
      channelId = withSound ? _kAdhkarEveningChannelId : _kAdhkarEveningSilentChannelId;
      channelName = withSound ? 'أذكار المساء (بصوت)' : 'أذكار المساء (صامت)';
    }

    final title = isMorning ? 'أذكار الصباح' : 'أذكار المساء';
    final body = isMorning ? 'حان الآن وقت أذكار الصباح، فاذكر الله.' : 'حان الآن وقت أذكار المساء، فاذكر الله.';

    await _notifications.show(
      isMorning ? _kMorningAdhkarAlarmId : _kEveningAdhkarAlarmId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'تنبيهات لقراءة أذكار الصباح والمساء',
          importance: Importance.max,
          priority: Priority.high,
          playSound: withSound,
          sound: withSound ? RawResourceAndroidNotificationSound(isMorning ? 'morning' : 'evening') : null,
        ),
      ),
    );
  }
}

class _NotificationContent {
  final String title;
  final String body;
  final String bigText;

  const _NotificationContent({
    required this.title,
    required this.body,
    required this.bigText,
  });
}

String _notificationPlaceLine(String raw) {
  var s = raw.trim();
  const prefix = 'موقعك الحالي:';
  while (s.startsWith(prefix)) {
    s = s.substring(prefix.length).trim();
  }
  return s.isEmpty ? 'مواقيت الصلاة' : s;
}

String _notificationHijriLine() {
  try {
    final prev = HijriCalendar.language;
    HijriCalendar.language = 'ar';
    final h = HijriCalendar.fromDate(DateTime.now());
    HijriCalendar.language = prev;
    return '${h.hDay} ${h.longMonthName} ${h.hYear}';
  } catch (_) {
    return '';
  }
}

String _formatAdhanWallClock(DateTime local) {
  final h = local.hour;
  final m = local.minute;
  final isPm = h >= 12;
  final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
  final period = isPm ? 'م' : 'ص';
  return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
}

_NotificationContent _buildNotificationContent({
  required String prayerName,
  required String location,
  required DateTime adhanLocalTime,
}) {
  final place = _notificationPlaceLine(location);
  final hijri = _notificationHijriLine();
  final timeStr = _formatAdhanWallClock(adhanLocalTime);
  final title = prayerName == 'الشروق' ? prayerName : 'صلاة $prayerName';
  final body = hijri.isEmpty ? timeStr : '$hijri   |   $timeStr';
  final bigText = '$title\n$body\n$place';
  return _NotificationContent(
    title: title,
    body: body,
    bigText: bigText,
  );
}

@pragma('vm:entry-point')
Future<void> _showAlarmCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IqamaNotificationService.instance.init();
  for (var i = 0; i < 6; i++) {
    await IqamaNotificationService.instance._showFromAlarmId(_kShowAlarmBaseId + i);
  }
  await IqamaNotificationService.instance._scheduleMidnightAlarm();
}

@pragma('vm:entry-point')
Future<void> _midnightRescheduleCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IqamaNotificationService.instance.init();
  await IqamaNotificationService.instance._recalculateAndReschedule();
}

String _prayerName(Prayer p, DateTime prayerDate) {
  switch (p) {
    case Prayer.fajr:
      return 'الفجر';
    case Prayer.sunrise:
      return 'الشروق';
    case Prayer.dhuhr:
      return prayerDate.weekday == DateTime.friday ? 'الجمعة' : 'الظهر';
    case Prayer.asr:
      return 'العصر';
    case Prayer.maghrib:
      return 'المغرب';
    case Prayer.isha:
      return 'العشاء';
    default:
      return 'الصلاة';
  }
}

@pragma('vm:entry-point')
Future<void> _morningAdhkarCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IqamaNotificationService.instance.init();
  await IqamaNotificationService.instance.showAdhkarNotification(isMorning: true);
  await IqamaNotificationService.instance.scheduleAdhkarAlarms();
}

@pragma('vm:entry-point')
Future<void> _eveningAdhkarCallback() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IqamaNotificationService.instance.init();
  await IqamaNotificationService.instance.showAdhkarNotification(isMorning: false);
  await IqamaNotificationService.instance.scheduleAdhkarAlarms();
}
