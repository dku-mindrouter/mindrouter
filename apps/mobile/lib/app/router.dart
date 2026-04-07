import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/constellation/presentation/screens/constellation_feed_screen.dart';
import '../features/emotion/presentation/screens/emotion_picker_screen.dart';
import '../features/nudge/presentation/screens/nudge_home_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/reaction/presentation/screens/star_detail_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/login',
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/today',
      builder: (context, state) => const EmotionPickerScreen(),
    ),
    GoRoute(
      path: '/constellation',
      builder: (context, state) => const ConstellationFeedScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: 'star/:starId',
          builder: (context, state) {
            final starId = state.pathParameters['starId'] ?? 'unknown';
            return StarDetailScreen(starId: starId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/nudges',
      builder: (context, state) => const NudgeHomeScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);

