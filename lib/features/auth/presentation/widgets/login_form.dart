import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../../common/di/dependencies.dart' as di;
import '../../../../common/utils/biometric_helper.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showBiometricDialog() async {
    final canCheck = await BiometricHelper.canCheckBiometrics();
    final isSupported = await BiometricHelper.isDeviceSupported();

    if (!canCheck && !isSupported) {
      if (mounted) context.go('/home');
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enable Biometrics'),
        content: const Text('Would you like to use biometrics for faster login next time?'),
        actions: [
          TextButton(
            onPressed: () async {
              await di.authLocalDataSource.setBiometricsEnabled(false);
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/home');
              }
            },
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () async {
              final authenticated = await BiometricHelper.authenticate();
              if (authenticated) {
                await di.authLocalDataSource.setBiometricsEnabled(true);
              }
              if (context.mounted) {
                Navigator.pop(context);
                context.go('/home');
              }
            },
            child: const Text('YES'),
          ),
        ],
      ),
    );
  }

  void _performLogin() async {
    // ocultar teclado al presionar el botón
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // llamada al usecase
        await di.loginUseCase(
          _usernameController.text.trim(),
          _passwordController.text,
        );

        if (mounted) {
          final isBiometricSet = await di.authLocalDataSource.isBiometricsEnabled();
          if (!isBiometricSet) {
             _showBiometricDialog();
          } else {
            context.go('/home');
          }
        }

      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error logging in. Please verify your credentials.';
            print('Login Error: $e');
          });
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: AppColors.accentGold50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LOG IN',
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'User',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.person, color: AppColors.darkBlue),
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Enter your username' : null,
              ),
              const SizedBox(height: 24),

              // Mensaje de error si existe
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 24),
              // Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock, color: AppColors.darkBlue),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.darkBlue.withOpacity(0.5),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v?.isEmpty ?? true) ? 'Enter your password' : null,
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _performLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: AppColors.darkBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkBlue),
                  )
                      : Text(
                    'LOG IN',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
