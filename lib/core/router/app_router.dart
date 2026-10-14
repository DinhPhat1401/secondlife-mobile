import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/dashboard/presentation/main_shell_screen.dart';

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
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Đăng Tin Đồ Gia Dụng')),
          body: const Center(child: Text('Wizard Đăng Tin 6 Bước Trợ Lý AI')),
        ),
      ),
      GoRoute(
        path: '/seller-onboarding',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Định Danh Người Bán (eKYC)')),
          body: const Center(child: Text('Onboarding & Chụp CCCD / Selfie')),
        ),
      ),
      GoRoute(
        path: '/credits/buy',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Mua Gói Tín Dụng')),
          body: const Center(child: Text('Bảng Giá & Chiết Khấu Gói Đăng Tin / AI')),
        ),
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
