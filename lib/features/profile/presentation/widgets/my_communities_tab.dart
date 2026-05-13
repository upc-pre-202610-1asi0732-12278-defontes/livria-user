import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:livria_user/features/communities/domain/entities/community.dart';
import 'package:provider/provider.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';
import '../../../auth/infrastructure/datasource/auth_remote_datasource.dart';
import '../../../communities/infrastructure/datasource/community_remote_datasource.dart';
import '../../../communities/infrastructure/datasource/post_remote_datasource.dart';
import '../../../communities/presentation/pages/community_detail_page.dart';
import '../providers/profile_provider.dart';

String _getCommunityTypeLabel(int type) {
  switch (type) {
    case 1: return 'LITERATURE';
    case 2: return 'NON-FICTION';
    case 3: return 'FICTION';
    case 4: return 'MANGAS & COMICS';
    case 5: return 'JUVENILE';
    case 6: return 'CHILDREN';
    case 7: return 'EBOOKS & AUDIOBOOKS';
    default: return 'GENERAL';
  }
}

class MyCommunitiesTab extends StatefulWidget {
  const MyCommunitiesTab({
    super.key,
  });

  @override
  State<MyCommunitiesTab> createState() => _MyCommunitiesTabState();
}

class _MyCommunitiesTabState extends State<MyCommunitiesTab> {

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final communities = provider.communities;

    if (communities.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: communities.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final community = communities[index];
        return _buildCommunitiesCard(context, community);
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.people, size: 60, color: AppColors.darkBlue.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            "You haven't created a community yet",
            style: TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Go explore our communities and create one of your own!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(Community community, double borderRadius) {
    const thumb = 55.0;
    return Container(
      width: thumb,
      height: thumb,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          community.type == 1 ? Icons.people : Icons.book,
          color: AppColors.darkBlue,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCommunitiesCard(BuildContext context, Community c) {
    //image
    const double borderRadius = 12.0;
    Widget imageContent;

    // 1. Si es URL de internet (http/https)
    if (c.image.startsWith('http')) {
      imageContent = Image.network(
        c.image,
        width: 55,
        height: 55,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(c, borderRadius),
      );
    }
    // 2. Si es Base64 (data:image...)
    else if (c.image.startsWith('data:image')) {
      try {
        // Limpiamos el prefijo y decodificamos
        final base64String = c.image.split(',').last;
        final Uint8List bytes = base64Decode(base64String);
        imageContent = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: 55,
          height: 55,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(c, borderRadius),
        );
      } catch (e) {
        imageContent = _buildPlaceholder(c, borderRadius);
      }
    }
    // 3. Si no es nada válido, mostramos placeholder
    else {
      imageContent = _buildPlaceholder(c, borderRadius);
    }

    return InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CommunityDetailPage(
              community: c,
              authLocalDataSource: AuthLocalDataSource(),
              authRemoteDataSource: AuthRemoteDataSource(),
              postRemoteDataSource: PostRemoteDataSource(),
              communityRemoteDataSource: CommunityRemoteDataSource(),
            ),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
            border: Border.all(color: AppColors.lightGrey),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Portada a la izquierda
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: imageContent,
              ),

              const SizedBox(width: 10),

              // Texto a la derecha
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(
                      c.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    // Autor
                    Text(
                      _getCommunityTypeLabel(c.type),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              InkWell(
                onTap: () => context.read<ProfileProvider>().removeCommunity(context, c.id),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.primaryOrange,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
    );
  }
}