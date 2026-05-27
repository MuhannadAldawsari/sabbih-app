import 'dart:async';
import 'dart:math';
import 'package:adhan/adhan.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

// ── GPS Notice (non-blocking banner data) ──────────────────────

class GpsNotice {
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;
  final int colorValue; // stored as int to avoid dart:ui in cubit

  const GpsNotice({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.colorValue = 0xFF4CAF50, // default: green
  });
}

// ── State ────────────────────────────────────────────────────────

class QiblaState {
  final double? qiblaAngle;
  final double? deviceHeading;
  final double? headingAccuracy;
  final bool needsCalibration;
  final bool isPhoneTilted;
  final double? lat;
  final double? lng;
  final String? errorMessage;
  final bool isLoading;
  final double? magneticFieldStrength; // µT
  final GpsNotice? gpsNotice;

  const QiblaState({
    this.qiblaAngle,
    this.deviceHeading,
    this.headingAccuracy,
    this.needsCalibration = false,
    this.isPhoneTilted = false,
    this.lat,
    this.lng,
    this.errorMessage,
    this.isLoading = false,
    this.magneticFieldStrength,
    this.gpsNotice,
  });

  bool get hasLocation => lat != null && lng != null;

  /// The rotation to apply to the qibla arrow (in turns, 0..1)
  /// so it always points toward Mecca regardless of device orientation.
  double? get qiblaRotationTurns {
    if (qiblaAngle == null || deviceHeading == null) return null;
    return ((qiblaAngle! - deviceHeading!) % 360) / 360;
  }

  QiblaState copyWith({
    double? qiblaAngle,
    double? deviceHeading,
    double? headingAccuracy,
    bool? needsCalibration,
    bool? isPhoneTilted,
    double? lat,
    double? lng,
    String? errorMessage,
    bool? isLoading,
    bool clearError = false,
    double? magneticFieldStrength,
    GpsNotice? gpsNotice,
    bool clearGpsNotice = false,
  }) {
    return QiblaState(
      qiblaAngle: qiblaAngle ?? this.qiblaAngle,
      deviceHeading: deviceHeading ?? this.deviceHeading,
      headingAccuracy: headingAccuracy ?? this.headingAccuracy,
      needsCalibration: needsCalibration ?? this.needsCalibration,
      isPhoneTilted: isPhoneTilted ?? this.isPhoneTilted,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
      magneticFieldStrength: magneticFieldStrength ?? this.magneticFieldStrength,
      gpsNotice: clearGpsNotice ? null : (gpsNotice ?? this.gpsNotice),
    );
  }
}

// ── Cubit ────────────────────────────────────────────────────────

class QiblaCubit extends Cubit<QiblaState> {
  QiblaCubit() : super(const QiblaState());

  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<MagnetometerEvent>? _magSub;

  static const double _tiltThreshold = 3.0; // m/s² deviation from gravity

  // Moving average buffer for magnetometer smoothing
  static const int _magWindowSize = 4;
  final List<double> _magBuffer = [];

  /// Start compass and tilt detection once location is known.
  void setLoading(bool loading) {
    emit(state.copyWith(isLoading: loading));
  }

  void setError(String error) {
    emit(state.copyWith(isLoading: false, errorMessage: error));
  }

  void setGpsNotice(GpsNotice notice) {
    emit(state.copyWith(gpsNotice: notice));
  }

  void clearGpsNotice() {
    emit(state.copyWith(clearGpsNotice: true));
  }

  void start(double lat, double lng) {
    final qiblaAngle = Qibla(Coordinates(lat, lng)).direction;

    emit(state.copyWith(
      lat: lat,
      lng: lng,
      qiblaAngle: qiblaAngle,
      clearError: true,
    ));

    _startCompass();
    _startTiltDetection();
    _startMagnetometer();
  }

  void _startCompass() {
    _compassSub?.cancel();
    _compassSub = FlutterCompass.events?.listen(
      (event) {
        if (isClosed) return;
        final rawHeading = event.heading;
        if (rawHeading == null) return;

        // Normalize from [-180, 180] to [0, 360]
        final heading = (rawHeading % 360 + 360) % 360;

        final accuracy = event.accuracy;
        // Combine compass accuracy signal with existing magnetometer signal
        final compassNeedsCal = accuracy != null && accuracy < 15;
        final magNeedsCal = _magnetometerNeedsCalibration(state.magneticFieldStrength);
        emit(state.copyWith(
          deviceHeading: heading,
          headingAccuracy: accuracy,
          needsCalibration: compassNeedsCal || magNeedsCal,
        ));
      },
      onError: (e) {
        if (isClosed) return;
        emit(state.copyWith(errorMessage: 'البوصلة غير متوفرة على هذا الجهاز'));
      },
    );
  }

  void _startMagnetometer() {
    _magSub?.cancel();
    _magSub = magnetometerEventStream(
      samplingPeriod: const Duration(milliseconds: 500),
    ).listen(
      (event) {
        if (isClosed) return;
        final raw = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z,
        );

        // Moving average: keep last _magWindowSize readings
        _magBuffer.add(raw);
        if (_magBuffer.length > _magWindowSize) _magBuffer.removeAt(0);
        final smoothed = _magBuffer.reduce((a, b) => a + b) / _magBuffer.length;

        final magNeedsCal = _magnetometerNeedsCalibration(smoothed);
        final compassNeedsCal =
            state.headingAccuracy != null && state.headingAccuracy! < 15;
        emit(state.copyWith(
          magneticFieldStrength: smoothed,
          needsCalibration: magNeedsCal || compassNeedsCal,
        ));
      },
      onError: (_) {},
    );
  }

  static bool _magnetometerNeedsCalibration(double? strength) {
    if (strength == null) return false;
    return strength < 20 || strength > 50;
  }

  void _startTiltDetection() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 500),
    ).listen(
      (event) {
        if (isClosed) return;
        // Gravity ~9.8 on z-axis when flat. Check deviation.
        final zDeviation = (event.z - 9.8).abs();
        final xyMagnitude = sqrt(event.x * event.x + event.y * event.y);
        final tilted = zDeviation > _tiltThreshold || xyMagnitude > _tiltThreshold;
        if (tilted != state.isPhoneTilted) {
          emit(state.copyWith(isPhoneTilted: tilted));
        }
      },
      onError: (_) {},
    );
  }

  /// Reset to empty state (e.g. when user switches to manual city selection).
  void reset() {
    _compassSub?.cancel();
    _accelSub?.cancel();
    _magSub?.cancel();
    _compassSub = null;
    _accelSub = null;
    _magSub = null;
    _magBuffer.clear();
    emit(const QiblaState());
  }

  @override
  Future<void> close() {
    _compassSub?.cancel();
    _accelSub?.cancel();
    _magSub?.cancel();
    return super.close();
  }
}
