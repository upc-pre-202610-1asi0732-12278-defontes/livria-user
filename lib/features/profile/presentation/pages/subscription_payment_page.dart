// features/profile/presentation/pages/subscription_proof_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../common/theme/app_colors.dart';
import '../providers/profile_provider.dart';

class SubscriptionProofPage extends StatefulWidget {
  const SubscriptionProofPage({super.key});

  @override
  State<SubscriptionProofPage> createState() => _SubscriptionProofPageState();
}

class _SubscriptionProofPageState extends State<SubscriptionProofPage> {
  File? _proofImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _proofImage = File(picked.path));
  }

  Future<void> _submit() async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a proof image first.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final provider = context.read<ProfileProvider>();
      final success = await provider.submitSubscriptionPaymentProof(
          context, _proofImage!);

      if (success && context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  "Payment proof sent! We'll verify it shortly. ✅"),
              backgroundColor: Colors.green),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text("PAYMENT PROOF",
            style: TextStyle(
                color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppColors.darkBlue),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softTeal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.softTeal),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Monthly Subscription Payment",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBlue,
                          fontSize: 16)),
                  SizedBox(height: 6),
                  Text(
                      "Please upload a screenshot of your payment of S/ 19.90 to our account. We will verify it within 24 hours.",
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preview imagen
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.softTeal, style: BorderStyle.solid),
                ),
                child: _proofImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_proofImage!, fit: BoxFit.cover),
                )
                    : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.upload_outlined,
                        size: 40, color: AppColors.softTeal),
                    SizedBox(height: 8),
                    Text("Tap to select screenshot",
                        style: TextStyle(color: AppColors.softTeal)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isUploading
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text("SEND PROOF",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}