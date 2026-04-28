import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../../common/di/dependencies.dart' as di;
import '../../../../common/utils/biometric_helper.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    // esperamos un poco para que se vea el logo
    await Future.delayed(const Duration(seconds: 2));

    // preguntamos al Caso de Uso si hay usuario guardado
    final user = await di.checkAuthStatusUseCase.call();

    // decidimos a dónde ir
    if (mounted) {
      if (user != null) {
        // Verificar si biometría está habilitada
        final isBiometricEnabled = await di.authLocalDataSource.isBiometricsEnabled();
        
        if (isBiometricEnabled) {
          final authenticated = await BiometricHelper.authenticate();
          if (authenticated) {
            if (mounted) context.go('/home');
          } else {
            // Si cancela o falla, podemos mandarlo a login o dejarlo reintentar
            // Por ahora, si falla biometría, le pedimos login de nuevo por seguridad
            if (mounted) context.go('/login');
          }
        } else {
          context.go('/home');
        }
      } else {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo.png',
          width: 150,
        ),
      ),
    );
  }
}
