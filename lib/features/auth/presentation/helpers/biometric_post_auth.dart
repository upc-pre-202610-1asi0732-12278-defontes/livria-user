import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/di/dependencies.dart' as di;
import '../../../../common/utils/biometric_helper.dart';

/// Tras login o registro: si aún no hay preferencia de biométricos y el dispositivo
/// puede usarlos, muestra el mismo diálogo que en login; siempre termina en `/home`.
Future<void> goHomeWithOptionalBiometricPrompt(BuildContext context) async {
  if (!context.mounted) return;

  final isBiometricSet = await di.authLocalDataSource.isBiometricsEnabled();
  if (isBiometricSet) {
    if (context.mounted) context.go('/home');
    return;
  }

  final canCheck = await BiometricHelper.canCheckBiometrics();
  final isSupported = await BiometricHelper.isDeviceSupported();
  if (!canCheck && !isSupported) {
    if (context.mounted) context.go('/home');
    return;
  }

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Enable Biometrics'),
      content: const Text(
        'Would you like to use biometrics for faster login next time?',
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await di.authLocalDataSource.setBiometricsEnabled(false);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            if (context.mounted) context.go('/home');
          },
          child: const Text('NO'),
        ),
        TextButton(
          onPressed: () async {
            final authenticated = await BiometricHelper.authenticate();
            if (authenticated) {
              await di.authLocalDataSource.setBiometricsEnabled(true);
            }
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            if (context.mounted) context.go('/home');
          },
          child: const Text('YES'),
        ),
      ],
    ),
  );
}
