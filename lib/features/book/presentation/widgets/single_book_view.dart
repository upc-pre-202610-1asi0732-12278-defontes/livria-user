import 'package:flutter/material.dart';
import 'package:livria_user/common/routes/app_router.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_remote_datasource.dart';
import 'package:livria_user/features/auth/infrastructure/model/user_model.dart';
import 'package:livria_user/features/book/application/services/favorite_service.dart';
import 'package:livria_user/features/book/infrastructure/repositories/favorite_repository_impl.dart';
import 'package:livria_user/features/book/infrastructure/datasource/favorite_remote_datasource.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_local_datasource.dart';
import 'package:http/http.dart' as http;
import 'package:livria_user/features/book/presentation/widgets/review_card.dart';
import '../../../../common/theme/app_colors.dart';
import '../../../auth/infrastructure/datasource/auth_local_datasource.dart';
import '../../application/services/exclusion_service.dart';
import '../../application/services/review_service.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository_impl.dart';
import '../../infrastructure/datasource/exclusion_remote_datasource.dart';
import '../../infrastructure/datasource/review_remote_datasource.dart';

import '../../../cart/domain/usecases/add_to_cart_usecase.dart';
import '../../../cart/infrastructure/repositories/cart_repository_impl.dart';
import '../../../cart/infrastructure/datasource/cart_remote_datasource.dart';
import '../../infrastructure/repositories/exclusion_repository_impl.dart';


class SingleBookView extends StatefulWidget {
  final Book b;
  final AuthLocalDataSource authLocalDataSource;
  final AuthRemoteDataSource authRemoteDataSource;
  const SingleBookView({super.key, required this.b, required this.authLocalDataSource, required this.authRemoteDataSource,});

  @override
  State<SingleBookView> createState() => _SingleBookViewState();
}

class _SingleBookViewState extends State<SingleBookView> {
  int _selectedQuantity = 1;
  final List<int> _quantities = [1, 2, 3, 4, 5];

  late final ReviewService _reviewService;
  final TextEditingController _reviewController = TextEditingController();
  int _newReviewStars = 0;

  late final AddToCartUseCase _addToCartUseCase;
  bool _isAddingToCart = false;

  late final FavoriteService _favoriteService;
  bool _isAddingToFavorites = false;
  bool _isFavorite = false;
  bool _isLoadingFavoriteStatus = true;

  String? _username;
  String? _userIconUrl;
  bool _isUserLoading = true;

  late final ExclusionService _exclusionService;
  bool _isAddingToExclusions = false;
  bool _isExcluded = false;
  bool _isLoadingExclusionStatus = true;

  @override
  void initState() {
    super.initState();
    _reviewService = ReviewService(
      ReviewRepositoryImpl(
        ReviewRemoteDataSource(authDs: AuthLocalDataSource()),
      ),
    );
    final cartDs = CartRemoteDataSource(client: http.Client());
    final cartRepo = CartRepositoryImpl(remoteDataSource: cartDs);
    _addToCartUseCase = AddToCartUseCase(cartRepo);

    final favoriteDs = FavoriteRemoteDataSource(
      client: http.Client(),
      authDs: AuthLocalDataSource(),
    );
    final favoriteRepo = FavoriteRepositoryImpl(remoteDataSource: favoriteDs);
    _favoriteService = FavoriteService(favoriteRepo);

    final exclusionDs = ExclusionRemoteDataSource(
      client: http.Client(),
      authDs: AuthLocalDataSource(),
    );
    final exclusionRepo = ExclusionRepositoryImpl(remoteDataSource: exclusionDs);
    _exclusionService = ExclusionService(exclusionRepo);

    _loadFavoriteStatus();
    _loadUserProfile();
    _loadExclusionStatus();
  }

  Future<void> _handleAddToCart() async {
    setState(() => _isAddingToCart = true);

    try {
      final authDs = AuthLocalDataSource();
      final userId = await authDs.getUserId();

      if (userId == null) {
        throw Exception("You must be logged in to add items.");
      }

      await _addToCartUseCase(
          widget.b.id,
          _selectedQuantity,
          userId
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book added to your cart! 📚'),
          backgroundColor: AppColors.darkBlue,
          duration: Duration(seconds: 2),
        ),
      );

      Scaffold.of(context).openEndDrawer();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppColors.errorRed),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  Future<void> _handlePostReview(int bookId) async {
    if (_reviewController.text.isEmpty || _newReviewStars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a comment and select a rating.')),
      );
      return;
    }
    try {
      await _reviewService.postReview(
        bookId: bookId,
        content: _reviewController.text,
        stars: _newReviewStars,
      );

      // Limpiar el formulario
      _reviewController.clear();
      setState(() {
        _newReviewStars = 0;
      });

      // Notificar éxito y actualizar la lista de reseñas
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review successfully published!')),
      );

      // forzamos un rebuild para que el FutureBuilder recargue la lista:
      setState(() {});

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish review: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadFavoriteStatus() async {
    final authDs = AuthLocalDataSource();
    final userId = await authDs.getUserId();

    if (userId != null) {
      try {
        final isFav = await _favoriteService.getIsFavoriteStatus(
          userId: userId,
          bookId: widget.b.id,
        );
        if (mounted) {
          setState(() {
            _isFavorite = isFav;
          });
        }
      } catch (e) {
        print('Error loading favorite status: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingFavoriteStatus = false;
      });
    }
  }

  Future<void> _handleAddToFavorites() async {
    setState(() => _isAddingToFavorites = true);

    try {
      final authDs = AuthLocalDataSource();
      final userId = await authDs.getUserId();

      if (userId == null) {
        if (!mounted) return;
        return;
      }

      await _favoriteService.addFavorite(
        userId: userId,
        bookId: widget.b.id,
      );

      if (!mounted) return;
      setState(() {
        _isFavorite = true;
        _isExcluded = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book added to your favorites! ❤️'),
          backgroundColor: AppColors.darkBlue,
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to favorites: ${e.toString()}'), backgroundColor: AppColors.errorRed),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingToFavorites = false);
      }
    }
  }

  Future<void> _handleRemoveFromFavorites() async {
    setState(() => _isAddingToFavorites = true);

    try {
      final authDs = AuthLocalDataSource();
      final userId = await authDs.getUserId();

      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in.'), backgroundColor: AppColors.errorRed),
        );
        return;
      }

      await _favoriteService.removeFavorite(
        userId: userId,
        bookId: widget.b.id,
      );

      if (!mounted) return;
      setState(() {
        _isFavorite = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book removed from favorites. 💔'),
          backgroundColor: AppColors.darkBlue,
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing favorite: ${e.toString()}'), backgroundColor: AppColors.errorRed),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingToFavorites = false);
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = await widget.authLocalDataSource.getUserId();
      final token = await widget.authLocalDataSource.getToken();
      if (userId != null && token != null) {
        final UserModel user = await widget.authRemoteDataSource.getUserProfile(userId, token);
        if (mounted) {
          setState(() {
            _username = user.username;
            _userIconUrl = user.icon;
            _isUserLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isUserLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error al cargar perfil de usuario: $e');
      if (mounted) {
        setState(() {
          _isUserLoading = false;
        });
      }
    }
  }

  Future<void> _loadExclusionStatus() async {
    final authDs = AuthLocalDataSource();
    final userId = await authDs.getUserId();

    if (userId != null) {
      try {
        final isExc = await _exclusionService.getIsExcludedStatus(
          userId: userId,
          bookId: widget.b.id,
        );
        if (mounted) {
          setState(() {
            _isExcluded = isExc;
          });
        }
      } catch (e) {
        print('Error loading exclusion status: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingExclusionStatus = false;
      });
    }
  }

  Future<void> _handleAddToExclusions() async {
    setState(() => _isAddingToExclusions = true);

    try {
      final authDs = AuthLocalDataSource();
      final userId = await authDs.getUserId();

      if (userId == null) {
        if (!mounted) return;
        return;
      }

      await _exclusionService.addExclusion(
        userId: userId,
        bookId: widget.b.id,
      );

      if (!mounted) return;
      setState(() {
        _isExcluded = true;
        _isFavorite = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book added to your exclusions! 🚫'),
          backgroundColor: AppColors.errorRed,
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to exclusions: ${e.toString()}'), backgroundColor: AppColors.errorRed),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingToExclusions = false);
      }
    }
  }

  Future<void> _handleRemoveFromExclusions() async {
    setState(() => _isAddingToExclusions = true);

    try {
      final authDs = AuthLocalDataSource();
      final userId = await authDs.getUserId();

      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in.'), backgroundColor: AppColors.errorRed),
        );
        return;
      }

      await _exclusionService.removeExclusion(
        userId: userId,
        bookId: widget.b.id,
      );

      if (!mounted) return;
      setState(() {
        _isExcluded = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book removed from exclusions. ✅'),
          backgroundColor: AppColors.darkBlue,
          duration: Duration(seconds: 2),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing exclusion: ${e.toString()}'), backgroundColor: AppColors.errorRed),
      );
    } finally {
      if (mounted) {
        setState(() => _isAddingToExclusions = false);
      }
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  // --- WIDGET PARA LAS ETIQUETAS LATERALES ---
  Widget _buildVerticalLabel(String text, Color color, double top, double left, int turn) {
    return Positioned(
      top: top,
      left: left,
      child: RotatedBox(
        quarterTurns: turn,
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  // --- SECCIÓN 1: ENCABEZADO Y DETALLE DEL LIBRO ---
  Widget _buildBookHeader(BuildContext context) {
    final t = Theme.of(context).textTheme;

    final bool hasStock = widget.b.stock > 0;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TÍTULO PRINCIPAL
          Text(
            widget.b.title.toUpperCase(),
            style: t.headlineLarge?.copyWith(
              color: AppColors.accentGold,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16.0),

          // ROW DE IMAGEN
          Align(
            alignment: Alignment.center,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 300,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Imagen de la Portada
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.network(
                      widget.b.cover,
                      height: 280,
                      width: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.lightGrey,
                        height: 280,
                        width: 170,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, color: AppColors.darkBlue),
                      ),
                    ),
                  ),
                  // Etiquetas Rotadas
                  _buildVerticalLabel(widget.b.genre.toUpperCase(), AppColors.primaryOrange, 0, -30, 3),
                  _buildVerticalLabel(widget.b.language.toUpperCase(), AppColors.vibrantBlue, 206, -30, 3),
                  _buildVerticalLabel(widget.b.author.toUpperCase(), AppColors.darkBlue, 0, 170, 1),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          // PRECIO Y BOTONES DE FAVORITOS
          Row(
            children: [
              GestureDetector(
                onTap: _isLoadingExclusionStatus || _isAddingToExclusions
                    ? null : _isExcluded
                    ? _handleRemoveFromExclusions : _handleAddToExclusions,
                child: _isLoadingExclusionStatus || _isAddingToExclusions
                    ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: CircularProgressIndicator(color: AppColors.errorRed, strokeWidth: 2)
                    )
                )
                    : Icon(
                  _isExcluded ? Icons.remove_circle : Icons.remove_circle_outline,
                  color: AppColors.errorRed,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16.0),
              GestureDetector(
                onTap: _isLoadingFavoriteStatus || _isAddingToFavorites
                    ? null : _isFavorite
                    ? _handleRemoveFromFavorites : _handleAddToFavorites,
                child: _isLoadingFavoriteStatus || _isAddingToFavorites
                    ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: Padding(
                        padding: EdgeInsets.all(4.0),
                        child: CircularProgressIndicator(color: AppColors.darkBlue, strokeWidth: 2)
                    )
                )
                    : Icon(
                  _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                  color: AppColors.darkBlue,
                  size: 32,
                ),
              ),
              const Spacer(),
              Text(
                'S/ ${widget.b.salePrice.toStringAsFixed(2)}',
                style: t.titleLarge?.copyWith(
                    color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 16.0),

          // --- CONTROLES DE CARRITO ---
          Row(
            children: [
              const Spacer(),

              Builder(
                  builder: (context) {
                    int maxPerPurchase = 5;
                    int realStock = widget.b.stock;

                    int limit = realStock < maxPerPurchase ? realStock : maxPerPurchase;

                    List<int> availableQuantities = List.generate(limit, (index) => index + 1);

                    return Opacity(
                      opacity: hasStock ? 1.0 : 0.5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15.0),
                        decoration: BoxDecoration(
                          color: AppColors.softTeal.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isDense: true,
                            style: t.bodyMedium?.copyWith(
                                color: AppColors.darkBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14
                            ),
                            value: hasStock ? _selectedQuantity : null,

                            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.darkBlue, size: 20),

                            items: availableQuantities.map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBlue, fontSize: 14)),
                              );
                            }).toList(),

                            onChanged: hasStock ? (int? newValue) {
                              setState(() {
                                _selectedQuantity = newValue!;
                              });
                            } : null,
                          ),
                        ),
                      ),
                    );
                  }
              ),

              const SizedBox(width: 16.0),

              // BOTÓN AÑADIR
              ElevatedButton(
                onPressed: (_isAddingToCart || !hasStock)
                    ? null
                    : _handleAddToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vibrantBlue,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  disabledForegroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                  minimumSize: const Size(120, 50),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: _isAddingToCart
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : Text(
                    hasStock ? 'ADD TO CART' : 'OUT OF STOCK',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- SECCIÓN 2: SINOPSIS ---
  Widget _buildSynopsis() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: AppColors.lightGrey.withOpacity(0.8))
        ),
        child: Text(
          widget.b.description,
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: 14, color: AppColors.black),
        ),
      ),
    );
  }

  // --- SECCIÓN 3: LISTA DE RESEÑAS DETALLADAS ---
  Widget _buildReviewsSection(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final int bookId = widget.b.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32.0, 24.0, 32.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'REVIEWS',
                style: t.headlineMedium?.copyWith(
                  color: AppColors.primaryOrange,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16.0),
              Text('Share a review for this book.', style: TextStyle(color: AppColors.darkBlue)),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Estrellas
              Row(
                children: [
                  ...List.generate(5, (index) {
                    final starValue = index + 1;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _newReviewStars = starValue;
                        });
                      },
                      child: Icon(
                        _newReviewStars >= starValue ? Icons.star : Icons.star_border,
                        color: AppColors.accentGold,
                        size: 30,
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 8.0),
              // Input de Texto
              TextField(
                controller: _reviewController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'What are your thoughts?',
                  hintStyle: TextStyle(color: AppColors.darkBlue.withOpacity(0.7)),
                  filled: true,
                  fillColor: AppColors.softTeal.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                ),
                style: TextStyle(
                  color: AppColors.darkBlue,
                  fontSize: 14.0,
                ),
              ),
              const SizedBox(height: 8.0),
              // Botón de Enviar Reseña
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _handlePostReview(widget.b.id),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.vibrantBlue,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('POST REVIEW', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        const SizedBox(height: 16.0),
        // Lista de reseñas
        FutureBuilder<List<Review>>(
          // Llama al servicio con el ID del libro actual
          future: _reviewService.getBookReviews(bookId),

          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text('Error loading reviews: ${snapshot.error}'),
              );
            }

            final reviews = snapshot.data ?? [];

            if (reviews.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text('There are no reviews for this book yet. Be the first!'),
              );
            }

            // Si hay reseñas, las renderizamos usando ReviewCard
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                // Solo inyectamos el icono si la reseña es del usuario logueado 
                // para asegurar que se vea su cambio de icono inmediatamente.
                final String? overrideIcon = (_username != null && reviews[index].username == _username)
                    ? _userIconUrl
                    : null;

                return ReviewCard(review: reviews[index], userIconUrl: overrideIcon,);
              },
            );
          },
        ),

        const SizedBox(height: 20.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildBookHeader(context),
            _buildSynopsis(),
            const SizedBox(height: 32.0),
            const Divider(height: 1, thickness: 2, color: AppColors.lightGrey),
            _buildReviewsSection(context),
          ],
        ),
      ),
    );
  }
}
