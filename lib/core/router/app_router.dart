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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      // Still checking session from disk
      if (authState.status == AuthStatus.initial || authState.status == AuthStatus.loading) {
        return null;
      }

      if (!isAuth && !isAuthRoute && state.matchedLocation != '/verify-email') {
        return '/login';
      }

      if (isAuth && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
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
        path: '/wallet',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Ví Nội Bộ SecondLife')),
          body: const Center(child: Text('Lịch Sử Biến Động Số Dư')),
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Thông Báo')),
          body: const Center(child: Text('Danh Sách Thông Báo')),
        ),
      ),
    ],
  );
});
