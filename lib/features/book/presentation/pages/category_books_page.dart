import 'package:flutter/material.dart';

import '../../../../common/theme/app_colors.dart';
import '../../application/services/book_service.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository_impl.dart';
import '../../infrastructure/datasource/book_remote_datasource.dart';
import '../widgets/book_filters_sheet.dart';
import '../widgets/horizontal_book_card.dart';

String getCategoryProperName(String type) {
  switch (type) {
    case "literature": return 'LITERATURE';
    case "non_fiction": return 'NON-FICTION';
    case "fiction": return 'FICTION';
    case "mangas_comics": return 'MANGAS & COMICS';
    case "juvenile": return 'JUVENILE';
    case "children": return 'CHILDREN';
    case "ebooks_audiobooks": return 'EBOOKS & AUDIOBOOKS';
    default: return 'GENERAL';
  }
}

class CategoryBooksPage extends StatefulWidget {
  final String genre;
  const CategoryBooksPage({super.key, required this.genre});

  @override
  State<CategoryBooksPage> createState() => _CategoryBooksPageState();
}

class _CategoryBooksPageState extends State<CategoryBooksPage> {
  late final BookService _service =
  BookService(BookRepositoryImpl(BookRemoteDataSource()));

  // filtros actuales
  BookFilterOptions _filters = const BookFilterOptions();

  Future<void> _openFilters() async {
    final applied = await showModalBottomSheet<BookFilterOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BookFiltersSheet(initial: _filters),
    );
    if (applied != null && mounted) {
      setState(() => _filters = applied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header (AsapCondensed)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
              child: Row(
                children: [
                  Text(
                    getCategoryProperName(widget.genre),
                    style: t.headlineMedium?.copyWith(
                      color: AppColors.primaryOrange,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _openFilters,
                    icon: const Icon(Icons.filter_list,
                        color: AppColors.primaryOrange),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: FutureBuilder<List<Book>>(
                future: _service.getByGenre(widget.genre),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }

                  var books = snap.data ?? const <Book>[];
                  if (books.isEmpty) {
                    return const Center(
                        child: Text('There are no books for this category'));
                  }

                  // aplicar filtros seleccionados
                  books = _filters.apply(books);

                  if (books.isEmpty) {
                    return const Center(child: Text('No results for the applied filters'));
                  }

                  // Grid de 2 columnas con celdas horizontales
                  return GridView.builder(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: books.length,
                    itemBuilder: (_, i) =>
                        HorizontalBookCard(books[i], t),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
