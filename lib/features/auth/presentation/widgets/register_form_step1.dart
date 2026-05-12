import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:email_validator/email_validator.dart';
import '../../../../common/theme/app_colors.dart';
import '../../infrastructure/registration_availability.dart';

class RegisterFormStep1 extends StatefulWidget {
  const RegisterFormStep1({super.key});

  @override
  State<RegisterFormStep1> createState() => _RegisterFormStep1State();
}

class _RegisterFormStep1State extends State<RegisterFormStep1> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Estado del Checkbox
  bool _termsAccepted = false;
  bool _isCheckingEmail = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must accept the terms and conditions to continue.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isCheckingEmail = true);

    try {
      final availability = await getRegistrationAvailability(
        email: _emailController.text,
      );

      if (availability.emailAvailable == false) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An account with that email already exists.'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }

      if (availability.emailAvailable != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not verify email. Please try again.'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
        return;
      }

      if (mounted) {
        context.push(
          '/register_step2',
          extra: {
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not verify email. Check your connection and try again.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingEmail = false);
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
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // --- Campo Email ---
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _buildInputDecoration('Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter your email';
                  if (!EmailValidator.validate(value)) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- Campo Contraseña ---
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _buildInputDecoration('Password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.darkBlue.withOpacity(0.5),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter a password';
                  if (value.length < 10) return 'Must be at least 10 characters';
                  if (value.length > 20) return 'Must be at most 20 characters';
                  if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Must contain at least 1 uppercase letter';
                  if (!RegExp(r'[a-z]').hasMatch(value)) return 'Must contain at least 1 lowercase letter';
                  if (!RegExp(r'[0-9]').hasMatch(value)) return 'Must contain at least 1 number';
                  if (RegExp(r'[\u{1F000}-\u{1FFFF}]|\u{FE0F}', unicode: true).hasMatch(value)) {
                    return 'Emojis are not allowed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- Campo Confirmar Contraseña ---
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: _buildInputDecoration('Confirm Password').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.darkBlue.withOpacity(0.5),
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Confirm your password';
                  if (value != _passwordController.text) return 'Passwords don\'t match';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- Checkbox Términos y Condiciones ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _termsAccepted,
                      activeColor: AppColors.primaryOrange,
                      onChanged: (bool? value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: textTheme.bodySmall?.copyWith(color: AppColors.darkBlue, fontSize: 13),
                        children: [
                          const TextSpan(text: 'I have read and agree to the '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),

                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showPrivacyDialog(context),
                          ),
                          const TextSpan(text: ' y los '),
                          TextSpan(
                            text: 'Terms and Conditions',
                            style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _showTermsDialog(context),
                          ),
                          const TextSpan(text: ' of Livria.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // --- Botón CONTINUAR ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isCheckingEmail ? null : _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGold,
                    foregroundColor: AppColors.darkBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isCheckingEmail
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.darkBlue,
                          ),
                        )
                      : Text(
                          'CONTINUE',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkBlue,
                            letterSpacing: 1.2,
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

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
      ),
    );
  }
}

void _showTermsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Terms and Conditions',
          style: TextStyle(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.bold
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            _termsAndConditionsText,
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}


void _showPrivacyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
              color: AppColors.primaryOrange,
              fontWeight: FontWeight.bold
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            _privacyPolicyText,
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}


const String _termsAndConditionsText = '''
Livria Application Terms and Conditions
Last Updated: 01/12/2025

Welcome to Livria! These Terms and Conditions ("Terms") govern your use of the Livria mobile application and related services (collectively, the "Service"), provided by Defontes ("Defontes," "we," "us," or "our").

By accessing or using the Service, you agree to be bound by these Terms and our Privacy Policy. If you disagree with any part of the terms, you must not access the Service.

1. Definitions
- Service: The Livria mobile application, developed and owned by Defontes.
- Defontes: The company providing the Service, located at Av. República de Chile 661.
- User: Any individual who accesses or uses the Service.
- Content: All text, images, photos, audio, video, and other material displayed on or available through the Service.

2. User Accounts and Access
2.1 Account Creation and Sessions
To access certain features of the Service, you must register for an account using a unique username and password. You agree to provide accurate, complete, and current information during the registration process.

2.2 Account Security
You are responsible for maintaining the confidentiality of your account credentials (username and password) and for all activities that occur under your account. You must notify us immediately upon becoming aware of any breach of security or unauthorized use of your account.

2.3 Local Storage
The Service uses client-side storage mechanisms (such as Local Storage) on your device to enhance functionality, improve performance, and maintain session continuity. By using the Service, you consent to the use of Local Storage for these purposes.

3. Privacy and Data Collection
3.1 Personal Information Collection
We collect personal information that you provide directly to us (e.g., during account registration) and automatically as you use the Service. The collection and use of your personal information are governed by our Privacy Policy, which is incorporated into these Terms by reference.

3.2 Digital Analytics and Tracking
We use third-party digital analytics solutions to track traffic, understand user behavior, and improve the Service. These tools may collect data such as device identifiers, IP addresses, usage patterns, and other non-personally identifiable information.

3.3 Use of Geolocation (Google Maps API)
The Service utilizes Google Maps API to provide book store locations and calculate optimized routes from your current location to a selected store. By using this feature, you acknowledge and agree that you are bound by the Google Maps/Google Earth Additional Terms of Service (including the Google Privacy Policy).

3.4 Device Permissions (Camera, Gallery, Geolocation)
The Service may request access to the following device features, which you may grant or deny:
- Camera and Gallery: Used solely for uploading user profile pictures, images related to book listings, or other content you choose to share.
- Geolocation: Used to determine your current location for the sole purpose of enabling the Google Maps routing feature.

4. Payment Terms (Izipay)
4.1 Payment Processor
Livria uses Izipay as a third-party payment processor to facilitate online payments for products or subscriptions. We do not store your full credit card details on our servers; this information is securely transmitted directly to Izipay.

4.2 One-Time and Recurring Payments
By initiating a payment, whether it is a one-time purchase or a recurring subscription, you authorize Defontes and its payment processor (Izipay) to charge your designated payment method for the transaction amount.
Recurring Subscriptions: If you subscribe to a service with recurring billing, you acknowledge that this subscription has an initial and recurring payment feature, and you accept responsibility for all recurring charges until you cancel your subscription.

4.3 Third-Party Risk
You acknowledge that payment processing is subject to the terms, conditions, and privacy policies of Izipay, in addition to these Terms. Defontes is not responsible for any errors or damages incurred due to the actions or inactions of Izipay.

5. Intellectual Property Rights
All Content, features, and functionality of the Service (including, but not limited to, all information, software, text, displays, images, video, and audio) are owned by Defontes, its licensors, or other providers of such material and are protected by international copyright, trademark, patent, trade secret, and other intellectual property or proprietary rights laws.

6. Termination and Suspension
We may terminate or suspend your access to the Service immediately, without prior notice or liability, for any reason whatsoever, including, without limitation, if you breach the Terms. Upon termination, your right to use the Service will immediately cease.

7. Disclaimers and Limitation of Liability
7.1 Disclaimer of Warranties
The Service is provided on an "AS IS" and "AS AVAILABLE" basis. Defontes makes no warranty or representation that: (i) the Service will be secure or available at any particular time or location; (ii) any defects or errors will be corrected; (iii) the Service is free of viruses or other harmful components.

7.2 Limitation of Liability
In no event shall Defontes, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from (i) your access to or use of or inability to access or use the Service; (ii) any content obtained from the Service; and (iii) unauthorized access, use, or alteration of your transmissions or content, whether based on warranty, contract, tort (including negligence), or any other legal theory.

8. Governing Law
These Terms shall be governed and construed in accordance with the laws of Peru, without regard to its conflict of law provisions.

9. Contact Information
If you have any questions about these Terms, you can contact us via the following methods:
- Email: support@defontes.com
- Local Address: Av. República de Chile 661
- Contact Form: Through the "Contact Us" form available on our landing page.

10. Acknowledgment
You acknowledge that you have read and understood these Terms and Conditions and agree to be bound by these Terms.
''';



const String _privacyPolicyText = '''
Livria Privacy Policy
Last Updated: 01/12/2025

1. Introduction
This Privacy Policy describes how Defontes ("we," "us," or "our") collects, uses, and discloses your information when you use the Livria mobile application (the "Service").
By using the Service, you agree to the collection and use of information in accordance with this policy. We are committed to protecting your personal data in compliance with the Peruvian Law on Personal Data Protection (Law N° 29733) and its Regulations.

2. Information We Collect
We collect several types of information to provide and improve our Service:

2.1 Personal Data
While using our Service, we may ask you to provide certain personally identifiable information, including but not limited to:
- Full Name
- Email address
- Phone number
- Physical Address (for order delivery)
- Username and Password

2.2 Usage Data
We may automatically collect information that your mobile device sends when you use the Service, such as your device model, operating system version, unique device identifiers, and other diagnostic data.

2.3 Device Permissions
- Location: We collect your location data only when you use the map feature to find nearby bookstores or calculate shipping routes.
- Camera and Gallery: We request access to your camera and photo library to allow you to upload or update your profile picture.

3. How We Use Your Information
Defontes uses the collected data for various purposes:
- To provide and maintain the Service.
- To notify you about changes to our Service.
- To allow you to participate in interactive features (e.g., Book Clubs, Reviews).
- To provide customer support.
- To process payments and deliver orders.
- To monitor the usage of the Service and detect technical issues.

4. Payment Information
We use third-party services for payment processing (e.g., Stripe, Izipay). We will not store or collect your payment card details. That information is provided directly to our third-party payment processors whose use of your personal information is governed by their Privacy Policy.

5. Data Sharing and Disclosure
We do not sell your personal data. We may share your information in the following situations:
- Service Providers: With third-party companies to facilitate our Service (e.g., delivery couriers, hosting providers).
- Legal Requirements: If required to do so by law or in response to valid requests by public authorities (e.g., a court or a government agency).

6. Data Security
The security of your data is important to us. We use commercially reasonable means (including SSL encryption and tokenization) to protect your Personal Data. However, remember that no method of transmission over the Internet is 100% secure.

7. Your Rights (ARCO Rights)
In accordance with Peruvian Law N° 29733, you have the right to:
- Access: Request a copy of the personal data we hold about you.
- Rectification: Request correction of inaccurate or incomplete data.
- Cancellation: Request deletion of your data when it is no longer necessary.
- Opposition: Object to the processing of your data for specific purposes.

To exercise these rights, please contact us at support@defontes.com.

8. Children's Privacy
Our Service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from anyone under the age of 13.

9. Changes to This Privacy Policy
We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.

10. Contact Us
If you have any questions about this Privacy Policy, please contact us:
- By email: support@defontes.com
- By mail: Av. República de Chile 661, Lima, Peru.
''';