import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../../common/utils/app_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../common/di/dependencies.dart' as di;

class RegisterFormStep2 extends StatefulWidget {
  // datos del paso 1
  final String email;
  final String password;

  const RegisterFormStep2({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<RegisterFormStep2> createState() => _RegisterFormStep2State();
}

class _RegisterFormStep2State extends State<RegisterFormStep2> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phraseController = TextEditingController();

  // manejar el estado de carga y la imagen seleccionada
  bool _isLoading = false;
  XFile? _imageFile;
  String? _errorMessage;

  String _captchaText = '';
  final _captchaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    final random = Random();
    setState(() {
      _captchaText = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
      _captchaController.clear();
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _usernameController.dispose();
    _phraseController.dispose();
    super.dispose();
  }

  // --- Lógica de Image Picker ---
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 500,
          maxHeight: 500,
          imageQuality: 50
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } catch (e) {
      print("Error al seleccionar imagen: $e");
    }
  }

  // --- Lógica de Registro Final ---
  void _performRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return; // Si el formulario no es válido, no hacer nada

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // llamar al UseCase con todos los datos (del Paso 1 y Paso 2)
      await di.registerUseCase(
        email: widget.email,
        password: widget.password,
        username: _usernameController.text.trim(),
        display: _nicknameController.text.trim(),
        phrase: _phraseController.text.trim(),
        iconPath: _imageFile?.path, // pasamos la ruta de la imagen
      );

      if (mounted) {
        context.go('/home');
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error en el registro. $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
                'REGISTER',
                style: textTheme.headlineMedium?.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Nickname
              TextFormField(
                controller: _nicknameController,
                decoration: _buildInputDecoration('Nickname (Display)'),
                validator: (v) => (v?.isEmpty ?? true) ? 'Enter your nickname' : null,
              ),
              const SizedBox(height: 24),

              // Username
              TextFormField(
                controller: _usernameController,
                decoration: _buildInputDecoration('Username'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your username';
                  if (v.length > 20) return 'Must be at most 20 characters';
                  if (!RegExp(r'^[a-z0-9]+$').hasMatch(v)) return 'Only lowercase letters and numbers allowed';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Frase (Opcional)
              TextFormField(
                controller: _phraseController,
                decoration: _buildInputDecoration('Phrase or Bio (Optional)'),
              ),
              const SizedBox(height: 24),

              // --- Sección de Foto de Perfil ---
              Text(
                'Profile Picture',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.darkBlue, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Vista previa de la imagen
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.file(
                    File(_imageFile!.path),
                    width: 100, height: 100, fit: BoxFit.cover,
                  ),
                ),
              if (_imageFile != null) const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón Cámara
                  IconButton(
                    icon: const FaIcon(AppIcons.camera),
                    color: AppColors.darkBlue,
                    iconSize: 30,
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(width: 24),
                  // Botón Galería
                  IconButton(
                    icon: const FaIcon(AppIcons.gallery),
                    color: AppColors.darkBlue,
                    iconSize: 30,
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              //CAPTCHA
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGrey),
                ),
                child: Column(
                  children: [
                    Text(
                      'CAPTCHA',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.vibrantBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Texto bizarro del captcha
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.darkBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: _captchaText.split('').asMap().entries.map((entry) {
                              final offsets = [-3.0, 2.0, -4.0, 3.0, -2.0, 4.0];
                              final rotations = [-0.15, 0.12, -0.1, 0.18, -0.08, 0.14];
                              final sizes = [22.0, 19.0, 24.0, 20.0, 23.0, 18.0];
                              final i = entry.key % 6;
                              return Transform.translate(
                                offset: Offset(0, offsets[i]),
                                child: Transform.rotate(
                                  angle: rotations[i],
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: sizes[i],
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkBlue,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.primaryOrange),
                          onPressed: _generateCaptcha,
                          tooltip: 'New captcha',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _captchaController,
                      decoration: _buildInputDecoration('Type the characters above'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter the captcha';
                        if (value.trim() != _captchaText) {
                          _generateCaptcha();
                          return 'Incorrect, try again';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),






              const SizedBox(height: 24),

              // --- Botón REGISTRARSE ---
              Row(
                children: [
                  // Botón BACK
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkBlue,
                          side: const BorderSide(color: AppColors.darkBlue, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'BACK',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkBlue,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón REGISTER
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _performRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGold,
                          foregroundColor: AppColors.darkBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppColors.darkBlue, strokeWidth: 3))
                            : Text(
                          'REGISTER',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkBlue,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5)),
    );
  }
}