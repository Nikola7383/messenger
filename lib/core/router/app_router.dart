import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:glasnik/features/auth/presentation/pages/auth_page.dart';
import 'package:glasnik/features/home/presentation/pages/home_page.dart';
import 'package:glasnik/features/settings/presentation/pages/settings_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isAuthenticated = authState.isAuthenticated;

    if (!isAuthenticated && state.location != '/auth') {
      return '/auth';
    }
    if (isAuthenticated && state.location == '/auth') {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
); 