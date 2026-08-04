import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/receive/receive_providers.dart';
import '../../features/receive/receive_screen.dart';
import '../../features/receive/result_screen.dart';
import '../../features/send/broadcasting_screen.dart';
import '../../features/send/compose_screen.dart';
import '../../features/send/send_providers.dart';
import '../../features/settings/settings_screen.dart';
import '../settings/app_settings.dart';
import '../theme/motion.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const send = '/send';
  static const broadcasting = '/send/broadcasting';
  static const receive = '/receive';
  static const result = '/receive/result';
  static const settings = '/settings';
  static const onboarding = '/onboarding';
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final onboardingSeen = ref.read(settingsProvider).onboardingSeen;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;

      if (!onboardingSeen && !isOnboarding) return AppRoutes.onboarding;
      if (onboardingSeen && isOnboarding) return AppRoutes.home;
      return null;
    },
    routes: [
      _route(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
      _route(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      _route(
        path: AppRoutes.settings,
        builder: (_, _) => const SettingsScreen(),
      ),
      _route(
        path: AppRoutes.send,
        builder: (_, _) => const ComposeScreen(),
        routes: [
          _route(
            path: 'broadcasting',
            builder: (_, _) => const BroadcastingScreen(),
            redirect: (context, state) =>
                ref.read(outgoingTransferProvider) == null
                ? AppRoutes.send
                : null,
          ),
        ],
      ),
      _route(
        path: AppRoutes.receive,
        builder: (_, _) => const ReceiveScreen(),
        routes: [
          _route(
            path: 'result',
            builder: (_, _) => const ResultScreen(),
            redirect: (context, state) =>
                ref.read(receivedPayloadProvider) == null
                ? AppRoutes.receive
                : null,
          ),
        ],
      ),
    ],
  );
});

GoRoute _route({
  required String path,
  required Widget Function(BuildContext, GoRouterState) builder,
  List<RouteBase> routes = const [],
  GoRouterRedirect? redirect,
}) => GoRoute(
  path: path,
  redirect: redirect,
  routes: routes,
  pageBuilder: (context, state) => CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: AppMotion.resolve(context, AppMotion.screenTransition),
    reverseTransitionDuration: AppMotion.resolve(
      context,
      AppMotion.screenTransition,
    ),
    child: builder(context, state),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  ),
);
