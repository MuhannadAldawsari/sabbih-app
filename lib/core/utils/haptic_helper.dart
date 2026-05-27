import 'package:vibration/vibration.dart';

class HapticHelper {
  // اهتزاز خفيف جداً لكل تسبيحة (نقرة سريعة)
  static Future<void> tasbihClick() async {
    // نتأكد أولاً أن الجهاز يدعم الاهتزاز
    if (await Vibration.hasVibrator()) {
      // 50 ميلي ثانية تعطي إحساساً ممتازاً يشبه ضغطة الزر الفعلي
      Vibration.vibrate(duration: 50); 
    }
  }

  // اهتزاز مميز (طويل أو بنمط معين) عند انتهاء دورة الذكر
  static Future<void> zikrCompleted() async {
    if (await Vibration.hasVibrator()) {
      // إذا كان الجهاز يدعم التحكم بالقوة (Amplitudes)
      if (await Vibration.hasAmplitudeControl()) {
        Vibration.vibrate(duration: 300, amplitude: 150); // اهتزاز واضح
      } else {
        // للأجهزة العادية: اهتزاز متقطع للتنبيه بانتهاء الذكر
        Vibration.vibrate(pattern: [0, 100, 100, 100]); 
      }
    }
  }
}
