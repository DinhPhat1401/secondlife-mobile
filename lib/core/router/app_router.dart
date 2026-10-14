import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/credits/presentation/screens/buy_credits_screen.dart';
import '../../features/credits/presentation/screens/credit_ledger_screen.dart';
import '../../features/dashboard/presentation/main_shell_screen.dart';
import '../../features/listings/presentation/screens/create_listing_wizard_screen.dart';
import '../../features/onboarding/presentation/screens/address_map_picker_screen.dart';
import '../../features/onboarding/presentation/screens/seller_onboarding_wizard_screen.dart';
import '../../features/orders/presentation/screens/seller_orders_screen.dart';
import '../../features/shipments/presentation/screens/shipment_tracking_screen.dart';
import '../../features/negotiations/presentation/screens/seller_negotiations_screen.dart';
import '../../features/chat/domain/chat_models.dart';
import '../../features/chat/presentation/screens/chat_inbox_screen.dart';
import '../../features/chat/presentation/screens/chat_conversation_screen.dart';
import '../../features/wallet/presentation/screens/seller_wallet_screen.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';
import '../../features/profile/presentation/screens/seller_profile_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authNotifierProvider);
    final isAuth = authState.isAuthenticated;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register' ||
        state.matchedLocation == '/forgot-password';

    // 1. While initial session is being checked from secure storage
    if (authState.status == AuthStatus.initial) {
      return null;
    }

    // 2. While login/register is in progress, stay on the auth screen
    if (authState.status == AuthStatus.loading && isAuthRoute) {
      return null;
    }

    // 3. Unauthenticated user trying to access protected screen -> redirect to /login
    if (!isAuth && !isAuthRoute && state.matchedLocation != '/verify-email') {
      return '/login';
    }

    // 4. Authenticated user trying to access /login or /register -> redirect to /dashboard
    if (isAuth && isAuthRoute) {
      return '/dashboard';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return VerifyEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainShellScreen(),
      ),
      GoRoute(
        path: '/create-listing',
        builder: (context, state) => const CreateListingWizardScreen(),
      ),
      GoRoute(
        path: '/seller-onboarding',
        builder: (context, state) => const SellerOnboardingWizardScreen(),
      ),
      GoRoute(
        path: '/seller-address',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddressMapPickerScreen(
            initialLat: extra?['initialLat'] as double?,
            initialLng: extra?['initialLng'] as double?,
            initialAddress: extra?['initialAddress'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/credits/buy',
        builder: (context, state) => const BuyCreditsScreen(),
      ),
      GoRoute(
        path: '/credits/ledger',
        builder: (context, state) => const CreditLedgerScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const SellerOrdersScreen(),
      ),
      GoRoute(
        path: '/shipments/:id/tracking',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ShipmentTrackingScreen(shipmentId: id);
        },
      ),
      GoRoute(
        path: '/negotiations',
        builder: (context, state) => const SellerNegotiationsScreen(),
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => const ChatInboxScreen(),
      ),
      GoRoute(
        path: '/chats/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final room = state.extra as ChatRoomModel?;
          return ChatConversationScreen(roomId: id, room: room);
        },
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const SellerWalletScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const SellerProfileScreen(),
      ),
    ],
  );
});
