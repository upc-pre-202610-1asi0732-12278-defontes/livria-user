import 'dart:io';
import 'package:flutter/material.dart';
import 'package:livria_user/common/theme/app_colors.dart';
import 'package:livria_user/common/utils/app_icons.dart';

typedef ShowSnackbar = void Function(String message, {required Color color});

class PostForm extends StatelessWidget {
  final bool isUserLoading;
  final String? username;
  final bool isPosting;
  final TextEditingController contentController;
  final File? selectedImageFile;
  final VoidCallback onGalleryPick;
  final VoidCallback onRemoveImage;
  final VoidCallback onPost;
  final VoidCallback onCameraPressed;
  final ShowSnackbar showSnackbar;

  const PostForm({
    super.key,
    required this.isUserLoading,
    required this.username,
    required this.isPosting,
    required this.contentController,
    required this.selectedImageFile,
    required this.onGalleryPick,
    required this.onRemoveImage,
    required this.onPost,
    required this.onCameraPressed,
    required this.showSnackbar,
  });

  @override
  Widget build(BuildContext context) {
    if (isUserLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(color: AppColors.primaryOrange, strokeWidth: 2),
        ),
      );
    }

    if (username == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'You must log in to post in this community.',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.red[800]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Formulario de POST
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: AbsorbPointer(
        absorbing: isPosting,
        child: Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.softTeal.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: contentController,
                decoration: InputDecoration(
                  hintText: 'What are your thoughts?',
                  hintStyle: TextStyle(color: AppColors.darkBlue.withOpacity(0.5)),
                  border: InputBorder.none,
                ),
                maxLines: null,
                minLines: 1,
              ),

              if (selectedImageFile != null) ...[
                const SizedBox(height: 12),
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(selectedImageFile!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Botón para remover la imagen
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.darkBlue.withOpacity(0.6),
                      ),
                      onPressed: onRemoveImage,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Botones de acción (Cámara, Imagen, Publicar)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: onCameraPressed,
                    icon: const Icon(AppIcons.camera, color: AppColors.vibrantBlue),
                    tooltip: 'Cámara',
                  ),
                  IconButton(
                    onPressed: onGalleryPick,
                    icon: const Icon(AppIcons.gallery, color: AppColors.vibrantBlue),
                    tooltip: 'Galería',
                  ),
                  const SizedBox(width: 8),

                  // Botón POST
                  isPosting
                      ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.vibrantBlue,
                      ),
                    ),
                  )
                      : ElevatedButton(
                    onPressed: onPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vibrantBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('POST', style: Theme.of(context).textTheme.labelLarge!.copyWith(color: AppColors.white)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}