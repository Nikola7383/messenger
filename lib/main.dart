import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glasnik/core/router/app_router.dart';
import 'package:glasnik/core/theme/app_theme.dart';
import 'package:glasnik/features/auth/data/repositories/auth_repository.dart';
import 'package:glasnik/features/auth/domain/repositories/auth_repository.dart';
import 'package:glasnik/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:glasnik/features/network/data/repositories/mesh_network_repository.dart';
import 'package:glasnik/features/network/domain/repositories/mesh_network_repository.dart';
import 'package:glasnik/features/network/presentation/blocs/network_bloc.dart';
import 'package:glasnik/features/security/data/repositories/verification_repository.dart';
import 'package:glasnik/features/security/domain/repositories/verification_repository.dart';
import 'package:glasnik/features/security/presentation/blocs/verification_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicijalizacija Hive-a
  await Hive.initFlutter();
  
  runApp(const GlasnikApp());
}

class GlasnikApp extends StatelessWidget {
  const GlasnikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IAuthRepository>(
          create: (context) => AuthRepository(),
        ),
        RepositoryProvider<IMeshNetworkRepository>(
          create: (context) => MeshNetworkRepository(),
        ),
        RepositoryProvider<IVerificationRepository>(
          create: (context) => VerificationRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<IAuthRepository>(),
            )..add(AuthCheckRequested()),
          ),
          BlocProvider<NetworkBloc>(
            create: (context) => NetworkBloc(
              networkRepository: context.read<IMeshNetworkRepository>(),
            ),
          ),
          BlocProvider<VerificationBloc>(
            create: (context) => VerificationBloc(
              verificationRepository: context.read<IVerificationRepository>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'Glasnik',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
