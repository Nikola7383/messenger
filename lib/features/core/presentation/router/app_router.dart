import 'package:glasnik/features/security/presentation/pages/verification_page.dart';

// U GoRouter konfiguraciji:
GoRoute(
  path: '/verification',
  name: 'verification',
  builder: (context, state) => BlocProvider(
    create: (context) => VerificationBloc(
      verificationRepository: context.read<IVerificationRepository>(),
    ),
    child: VerificationPage(
      currentRole: context.read<AuthBloc>().state.user?.role ?? UserRole.guest,
    ),
  ),
), 