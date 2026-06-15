import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:livria_user/common/theme/app_colors.dart';
import 'package:livria_user/common/utils/app_icons.dart';
import '../../../../common/services/analytics_service.dart';
import '../../../profile/presentation/pages/subscription_payment_page.dart';
import '../../application/services/community_service.dart';
import '../../domain/entities/community.dart';
import '../../infrastructure/repositories/community_repository_api.dart';
import '../../infrastructure/datasource/community_remote_datasource.dart';
import '../../presentation/widgets/community_card.dart';
import '../../domain/usecases/create_community_usecase.dart';
import 'create_community_page.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';
import '../../../auth/infrastructure/datasource/auth_remote_datasource.dart';
import '../../../auth/infrastructure/model/user_model.dart';


class CommunitiesPage extends StatefulWidget {
  final AuthLocalDataSource authLocalDataSource;
  final AuthRemoteDataSource authRemoteDataSource;

  const CommunitiesPage(
      {
        super.key,
        required this.authLocalDataSource,
        required this.authRemoteDataSource,
      });

  @override
  State<CommunitiesPage> createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage> {
  final TextEditingController _searchController = TextEditingController();

  final CommunityRemoteDataSource _dataSource = CommunityRemoteDataSource();
  late final CommunityRepositoryApi _repository = CommunityRepositoryApi(dataSource: _dataSource);
  late final CommunityService _communityService = CommunityService(_repository);
  late final CreateCommunityUseCase _createCommunityUseCase = CreateCommunityUseCase(_repository);

  List<Community> _filteredCommunities = [];
  bool _isLoading = true;
  String? _hasError;

  bool _isCheckingAccess = true;
  bool _hasCommunityPlan = false;
  String _userAccessError = '';

  @override
  void initState() {
    super.initState();

    // Exp 4
    LivriaAnalytics.logEvent('click_community_section', null);

    _checkSubscriptionAndLoadCommunities();
  }

  Future<void> _fetchCommunities({String query = ''}) async {
    if (_hasError == null || !_isLoading) {
      setState(() {
        _isLoading = true;
        _hasError = null;
      });
    }

    try {
      final results = await _communityService.findCommunities(query);

      setState(() {
        _filteredCommunities = results;
        _isLoading = false;
        _hasError = null;
      });
    } catch (e) {
      setState(() {
        _hasError = 'The communities could not be loaded. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkSubscriptionAndLoadCommunities() async {
    setState(() {
      _isCheckingAccess = true;
      _userAccessError = '';
    });

    try {
      final userId = await widget.authLocalDataSource.getUserId();
      final token = await widget.authLocalDataSource.getToken();

      if (userId == null || token == null) {
        throw Exception('User is not logged in or token is missing.');
      }

      // obtener perfil
      final UserModel user = await widget.authRemoteDataSource.getUserProfile(userId, token);

      // verificar suscripción
      const requiredPlan = 'communityplan';
      final hasPlan = user.subscription == requiredPlan;

      if (mounted) {
        setState(() {
          _isCheckingAccess = false;
          _hasCommunityPlan = hasPlan;
        });

        // Exp 4
        if (!hasPlan) {
          LivriaAnalytics.logEvent('view_paywall_screen', {
            'subscription_required': 'communityplan',
          });
        }

        // cargar comunidades si tiene plan
        if (hasPlan) {
          _fetchCommunities();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingAccess = false;
          _hasCommunityPlan = false;
          _userAccessError = 'Error: could not verify user subscription status.';
        });
      }
    }
  }

  void _performSearch(String query) {
    _fetchCommunities(query: query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // verificando plan
    if (_isCheckingAccess) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
      );
    }

    // acceso denegado
    if (!_hasCommunityPlan) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: _buildAccessDeniedView(),
        ),
      );
    }

    // vista de comunidades
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              _buildHeader(context),

              const SizedBox(height: 20),

              _buildSearchBar(context),

              const SizedBox(height: 24),

              Expanded(
                child: _buildCommunityGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'COMMUNITIES',
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
            color: AppColors.darkBlue,
            fontSize: 30,
          ),
        ),

        OutlinedButton.icon(
          onPressed: () async {
            final bool? result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CreateCommunityPage(
                  createCommunityUseCase: _createCommunityUseCase,
                  authLocalDataSource: widget.authLocalDataSource,
                  authRemoteDataSource: widget.authRemoteDataSource,
                ),
              ),
            );

            if (result == true) {
              _fetchCommunities();
            }
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            side: const BorderSide(color: AppColors.primaryOrange, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: AppColors.white,
          ),
          icon: const FaIcon(
            AppIcons.post,
            size: 16,
            color: AppColors.primaryOrange,
          ),
          label: Text(
            'CREATE +',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              fontSize: 14,
              color: AppColors.primaryOrange,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    const double containerBorderRadius = 10.0;
    const double borderThickness = 1.5;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(containerBorderRadius),
        border: Border.all(color: AppColors.accentGold, width: borderThickness),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: _performSearch,
              textInputAction: TextInputAction.search,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: 'Enter a title to search',
                hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.accentGold,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
            ),
          ),

          Container(width: borderThickness, color: AppColors.accentGold),

          GestureDetector(
            onTap: () => _performSearch(_searchController.text),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(containerBorderRadius),
                bottomRight: Radius.circular(containerBorderRadius),
              ),
              child: Container(
                width: 50,
                height: 50 - (borderThickness * 2),
                color: AppColors.primaryOrange,
                child: const FaIcon(
                  AppIcons.search,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
    }

    if (_hasError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_hasError!, style: Theme.of(context).textTheme.titleMedium!.copyWith(color: AppColors.errorRed)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCommunities,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange),
              child: const Text('Retry', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      );
    }

    if (_filteredCommunities.isEmpty) {
      return Center(
        child: Text(
          _searchController.text.isEmpty
              ? 'No available.'
              : 'No matches for "${_searchController.text}"',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    final List<Community> reversedCommunities = _filteredCommunities.reversed.toList();

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredCommunities.length,
      itemBuilder: (context, index) {
        return CommunityCard(
          community: reversedCommunities[index],
        );
      },
    );
  }

  Widget _buildAccessDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 80,
              color: AppColors.secondaryYellow,
            ),
            const SizedBox(height: 24),
            Text(
              _userAccessError.isNotEmpty
                  ? _userAccessError
                  : 'Subscription required.',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: AppColors.errorRed,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To access this feature and join communities, please subscribe to the Community Plan.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Exp 4
                  LivriaAnalytics.logEvent('click_subscribe_plan', {
                    'plan': 'communityplan',
                    'trigger': 'communities_paywall',
                  });

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SubscriptionProofPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'SUBSCRIBE NOW',
                  style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
