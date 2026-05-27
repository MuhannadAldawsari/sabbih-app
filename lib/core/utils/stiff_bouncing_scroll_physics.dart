import 'package:flutter/material.dart';

class StiffBouncingScrollPhysics extends BouncingScrollPhysics {
  const StiffBouncingScrollPhysics({super.parent});

  @override
  StiffBouncingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return StiffBouncingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double frictionFactor(double overscrollFraction) {
    // الرقم الافتراضي هو 1.0. 
    // ضربه في 0.25 يجعل الارتداد قصيراً جداً وأثقل، فيمنع الفراغ الكبير.
    return super.frictionFactor(overscrollFraction) * 0.30; 
  }
}
