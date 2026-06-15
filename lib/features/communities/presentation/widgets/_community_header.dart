// community_header.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:livria_user/common/theme/app_colors.dart';
import 'package:livria_user/common/utils/app_icons.dart';
import '../../domain/entities/community.dart';
import 'dart:convert';
import 'dart:typed_data';

class CommunityHeader extends StatelessWidget {
  final Community community;
  final String Function(int type) getCommunityTypeLabel;
  final VoidCallback onJoinPressed;
  final bool isJoined;

  const CommunityHeader({
    super.key,
    required this.community,
    required this.getCommunityTypeLabel,
    required this.onJoinPressed,
    this.isJoined = false,
  });

  Widget _CommunityImageContent({
    required String imageData,
    required Widget placeholder,
    required BoxFit fit,
  }) {
    if (imageData.isEmpty) {
      return placeholder;
    }

    if (imageData.startsWith('http')) {
      return Image.network(
        imageData,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    if (imageData.startsWith('data:image')) {
      try {
        final base64String = imageData.split(',').last;
        final Uint8List bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => placeholder,
        );
      } catch (e) {
        return placeholder;
      }
    }

    try {
      final Uint8List bytes = base64Decode(imageData);
      return Image.memory(bytes, fit: fit);
    } catch (e) {
      return placeholder;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double bannerHeight = 150;
    const double iconSize = 80;
    const double iconBottomMargin = 16;

    final Color buttonColor = isJoined ? Colors.red[700]! : AppColors.primaryOrange;
    final String buttonText = isJoined ? 'LEAVE' : 'JOIN +';
    final Icon buttonIcon = isJoined
        ? const Icon(Icons.exit_to_app_rounded, size: 18, color: AppColors.white)
        : const FaIcon(AppIcons.post, size: 18, color: AppColors.white);

    final Widget bannerPlaceholder = Container(
      color: AppColors.softTeal.withOpacity(0.5),
      child: const Center(
        child: Text('Banner Image Failed', style: TextStyle(color: AppColors.darkBlue)),
      ),
    );

    final Widget iconPlaceholder = Container(
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Icon(
          Icons.group,
          size: iconSize * 0.5,
          color: AppColors.softTeal,
        ),
      ),
    );


    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: bannerHeight,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.softTeal,
          ),
          child: _CommunityImageContent(
            imageData: community.banner,
            placeholder: bannerPlaceholder,
            fit: BoxFit.cover,
          ),
        ),

        Padding(
          padding: EdgeInsets.only(top: bannerHeight - (iconBottomMargin + iconSize / 2), left: 16.0, right: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    margin: const EdgeInsets.only(right: 16.0),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: AppColors.primaryOrange, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _CommunityImageContent(
                        imageData: community.image,
                        placeholder: iconPlaceholder,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: onJoinPressed,
                    icon: buttonIcon,
                    label: Text(
                        buttonText,
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(color: AppColors.white)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                community.name.toUpperCase(),
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkBlue,
                ),
              ),
              Text(
                getCommunityTypeLabel(community.type),
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: AppColors.secondaryYellow,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: AppColors.lightGrey.withOpacity(0.8))
                ),
                child: Text(
                  community.description,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: AppColors.black.withOpacity(0.7),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}