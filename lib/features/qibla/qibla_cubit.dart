import 'dart:async';
import 'dart:math';
import 'package:adhan/adhan.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';

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
    );
  }
}

// ── Cubit ────────────────────────────────────────────────────────

class QiblaCubit extends Cubit<QiblaState> {
  QiblaCubit() : super(const QiblaState());

  StreamSubscription<CompassEvent>? _compassSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;

  static const double _tiltThreshold = 3.0; // m/s² deviation from gravity

  /// Start compass and tilt detection once location is known.
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
        final needsCal = accuracy != null && accuracy < 15;

        emit(state.copyWith(
          deviceHeading: heading,
          headingAccuracy: accuracy,
          needsCalibration: needsCal,
        ));
      },
      onError: (e) {
        if (isClosed) return;
        emit(state.copyWith(errorMessage: 'البوصلة غير متوفرة على هذا الجهاز'));
      },
    );
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

  @override
  Future<void> close() {
    _compassSub?.cancel();
    _accelSub?.cancel();
    return super.close();
  }
}
