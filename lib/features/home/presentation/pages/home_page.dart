import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_local_datasource.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_remote_datasource.dart';
import 'package:livria_user/features/auth/infrastructure/model/user_model.dart';
import 'package:livria_user/features/book/presentation/pages/category_books_page.dart';

import '../../../book/presentation/widgets/horizontal_book_card.dart';

import '../../../../common/theme/app_colors.dart';
import '../../../book/application/services/book_service.dart';
import '../../../book/domain/entities/book.dart';
import '../../../book/domain/repositories/book_repository_impl.dart';
import '../../../book/infrastructure/datasource/book_remote_datasource.dart';
import '../../application/services/home_service.dart';

class HomePage extends StatelessWidget {
  final AuthLocalDataSource authLocalDataSource;
  final AuthRemoteDataSource authRemoteDataSource;

  const HomePage({super.key, required this.authLocalDataSource, required this.authRemoteDataSource,});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: _HomeView(authLocalDataSource: authLocalDataSource, authRemoteDataSource: authRemoteDataSource,),
    );
  }
}

class _HomeView extends StatefulWidget {
  final AuthLocalDataSource authLocalDataSource;
  final AuthRemoteDataSource authRemoteDataSource;
  const _HomeView({required this.authLocalDataSource, required this.authRemoteDataSource,});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  late final BookService _bookService = BookService(
    BookRepositoryImpl(
      BookRemoteDataSource(),
    ),
  );

  late final HomeService _homeService = HomeService(_bookService);

  late Future<List<Book>> _allBooksFuture;
  late Future<List<String>> _genresFuture;

  @override
  void initState() {
    super.initState();
    _allBooksFuture = _bookService.getAllBooks();
    _genresFuture = _homeService.getAllGenres();
  }

  Color _colorForRow(int i) {
    switch (i % 3) {
      case 0:
        return AppColors.vibrantBlue;
      case 1:
        return AppColors.primaryOrange;
      default:
        return AppColors.secondaryYellow;
    }
  }

  Widget _buildCategoryCarousel(
      BuildContext context,
      String genre,
      List<Book> allBooks,
      int index,
      ) {
    final genreBooks = allBooks
        .where((b) => b.genre.toLowerCase() == genre.toLowerCase())
        .toList();

    if (genreBooks.isEmpty) {
      return const SizedBox.shrink();
    }

    final sectionColor = _colorForRow(index);

    final screenWidth = MediaQuery.of(context).size.width;

    const double arrowReservedSpace = 24.0;
    const double totalSymmetricSpace = arrowReservedSpace * 2;

    const double listViewPadding = 4.0;
    const double itemGap = 16.0;

    final availableWidth = screenWidth - totalSymmetricSpace;

    final availableContentWidth = availableWidth - (listViewPadding * 2);

    final itemWidth = (availableContentWidth - itemGap) / 2;

    final carouselHeight = (itemWidth / 1.8) + 50.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32.0, 16.0, 24.0, 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  getCategoryProperName(genre),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: sectionColor,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.go('/categories/${Uri.encodeComponent(genre)}');
                },
                child: Text(
                  'See more (${genreBooks.length})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: sectionColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),

        _CategoryCarouselWithArrows(
          genreBooks: genreBooks,
          itemWidth: itemWidth,
          carouselHeight: carouselHeight,
          sectionColor: sectionColor,
          arrowReservedSpace: arrowReservedSpace,
          listViewPadding: listViewPadding,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _genresFuture,
      builder: (context, genresSnap) {
        if (genresSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (genresSnap.hasError) {
          return Center(child: Text('Error al cargar géneros: ${genresSnap.error}'));
        }

        final genres = genresSnap.data ?? [];

        return FutureBuilder<List<Book>>(
          future: _allBooksFuture,
          builder: (context, booksSnap) {
            if (booksSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (booksSnap.hasError) {
              return Center(child: Text('Error al cargar libros: ${booksSnap.error}'));
            }

            final allBooks = booksSnap.data ?? [];

            if (allBooks.isEmpty) {
              return const Center(child: Text('No hay contenido para mostrar.'));
            }

            return _HomeContent(
              genres: genres,
              allBooks: allBooks,
              buildCategoryCarousel: _buildCategoryCarousel,
              authRemoteDataSource: widget.authRemoteDataSource,
              authLocalDataSource: widget.authLocalDataSource
            );
          },
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  final List<String> genres;
  final List<Book> allBooks;
  final Widget Function(BuildContext, String, List<Book>, int) buildCategoryCarousel;

  final AuthLocalDataSource authLocalDataSource;
  final AuthRemoteDataSource authRemoteDataSource;

  const _HomeContent({
    required this.genres,
    required this.allBooks,
    required this.buildCategoryCarousel,
    required this.authLocalDataSource,
    required this.authRemoteDataSource,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _Banner(authRemoteDataSource: authRemoteDataSource, authLocalDataSource: authLocalDataSource,),

          ...genres.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final genre = entry.value;
            return buildCategoryCarousel(context, genre, allBooks, index);
          }),
        ],
      ),
    );
  }
}
class _Banner extends StatefulWidget {
  final AuthLocalDataSource authLocalDataSource;
  final AuthRemoteDataSource authRemoteDataSource;

  const _Banner({
    required this.authLocalDataSource,
    required this.authRemoteDataSource,
  });

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> {
  bool _isCheckingAccess = true;
  bool _hasCommunityPlan = false;
  String _userAccessError = '';

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      width: screenWidth,
      decoration: const BoxDecoration(
        color: AppColors.black,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/community.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
              child: SizedBox(
                width: screenWidth * 0.70,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      !_hasCommunityPlan ? 'COMMUNITY PLAN' : 'COMMUNITIES FOR YOU',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.secondaryYellow,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      !_hasCommunityPlan ? 'Connect with other readers, share your thoughts and join spaces where reading come alive' :
                      'Discover and join communities based on your interests... Or create one!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.white.withOpacity(0.9),
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () {
                        !_hasCommunityPlan ? GoRouter.of(context).go('/profile/subscription') : GoRouter.of(context).go('/communities');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        !_hasCommunityPlan ? 'GET IT HERE' : 'GO NOW',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.darkBlue
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _CategoryCarouselWithArrows extends StatefulWidget {
  final List<Book> genreBooks;
  final double itemWidth;
  final double carouselHeight;
  final Color sectionColor;
  final double arrowReservedSpace;
  final double listViewPadding;

  const _CategoryCarouselWithArrows({
    required this.genreBooks,
    required this.itemWidth,
    required this.carouselHeight,
    required this.sectionColor,
    required this.arrowReservedSpace,
    required this.listViewPadding,
  });

  @override
  State<_CategoryCarouselWithArrows> createState() =>
      _CategoryCarouselWithArrowsState();
}

class _CategoryCarouselWithArrowsState
    extends State<_CategoryCarouselWithArrows> {
  late final ScrollController _scrollController;

  static const double _verticalCarouselPadding = 2.0;
  static const double _arrowIconPadding = 8.0;
  static const double _itemGap = 16.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scroll(double direction) {
    if (!_scrollController.hasClients) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    final minExtent = _scrollController.position.minScrollExtent;
    final currentOffset = _scrollController.offset;

    final scrollUnit = (widget.itemWidth * 2.0) + (_itemGap * 2.0);
    final offsetDistance = scrollUnit * direction;

    final newOffset = currentOffset + offsetDistance;
    double targetOffset = newOffset;

    if (direction > 0) {
      if (currentOffset == maxExtent) {
        targetOffset = minExtent;
      } else {
        targetOffset = newOffset.clamp(minExtent, maxExtent);
      }
    }
    else if (direction < 0) {
      if (currentOffset == minExtent) {
        targetOffset = maxExtent;
      } else {
        targetOffset = newOffset.clamp(minExtent, maxExtent);
      }
    }

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollLeft() => _scroll(-1);
  void _scrollRight() => _scroll(1);

  Widget _buildArrowButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: widget.sectionColor, size: 16),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.white.withOpacity(0.7),
        padding: const EdgeInsets.all(4),
        minimumSize: Size.zero,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      onPressed: onPressed,
    );
  }


  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final double arrowSpace = widget.arrowReservedSpace;
    final double innerPadding = widget.listViewPadding;

    return SizedBox(
      height: widget.carouselHeight + _verticalCarouselPadding * 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _verticalCarouselPadding),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: arrowSpace,
              child: Padding(
                padding: const EdgeInsets.only(left: _arrowIconPadding),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildArrowButton(Icons.arrow_back_ios, _scrollLeft),
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: innerPadding),
                itemCount: widget.genreBooks.length,
                itemBuilder: (context, index) {
                  final book = widget.genreBooks[index];
                  final isLast = index == widget.genreBooks.length - 1;

                  return Padding(
                    padding: EdgeInsets.only(right: isLast ? 0.0 : _itemGap, bottom: 24.0,),
                    child: SizedBox(
                      width: widget.itemWidth,
                      child: HorizontalBookCard(book, t),
                    ),
                  );
                },
              ),
            ),

            SizedBox(
              width: arrowSpace,
              child: Padding(
                padding: const EdgeInsets.only(right: _arrowIconPadding),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildArrowButton(Icons.arrow_forward_ios, _scrollRight),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}