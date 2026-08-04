import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const screenTransition = Duration(milliseconds: 320);
  static const pressDown = Duration(milliseconds: 100);
  static const pressUp = Duration(milliseconds: 150);
  static const segmentSwitch = Duration(milliseconds: 220);
  static const progressIncrement = Duration(milliseconds: 180);
  static const successReveal = Duration(milliseconds: 500);
  static const successDraw = Duration(milliseconds: 250);
  static const successContentFade = Duration(milliseconds: 250);
  static const successContentDelay = Duration(milliseconds: 100);
  static const errorShake = Duration(milliseconds: 400);
  static const shimmerLoop = Duration(milliseconds: 1200);
  static const reducedFade = Duration(milliseconds: 80);
  static const toastDuration = Duration(milliseconds: 2500);
  static const snackbarDuration = Duration(seconds: 4);

  static const screenCurve = Curves.easeOutCubic;
  static const pressCurve = Curves.easeOut;
  static const segmentCurve = Curves.easeInOutCubic;
  static const progressCurve = Curves.easeOut;

  static const _reduceThreshold = Duration(milliseconds: 200);

  static bool reduceMotionOf(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration resolve(BuildContext context, Duration duration) {
    if (!reduceMotionOf(context)) return duration;
    return duration > _reduceThreshold ? reducedFade : duration;
  }

  static Curve resolveCurve(BuildContext context, Curve curve) =>
      reduceMotionOf(context) ? Curves.easeOut : curve;
}

final class FadeThroughPageTransition extends PageTransitionsBuilder {
  const FadeThroughPageTransition();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduceMotionOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.screenCurve,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
