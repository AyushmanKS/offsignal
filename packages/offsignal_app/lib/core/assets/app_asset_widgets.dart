import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

import 'app_assets.dart';

class AppIcon extends StatelessWidget {
  const AppIcon(this.path, {super.key, this.size = 24, this.color});

  final String path;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}

class AppSuccessAnimation extends StatelessWidget {
  const AppSuccessAnimation({
    super.key,
    this.size = 120,
    this.repeat = false,
    this.onComplete,
  });

  final double size;
  final bool repeat;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      AppAnimations.successCheckmark,
      width: size,
      height: size,
      repeat: repeat,
      onLoaded: (composition) {
        if (onComplete == null) return;
        Future.delayed(composition.duration, onComplete);
      },
    );
  }
}

class AppOnboardingImage extends StatelessWidget {
  const AppOnboardingImage(this.path, {super.key, this.fit = BoxFit.contain});

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => Image.asset(path, fit: fit);
}
