import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../common/theme/app_colors.dart';
import '../../application/services/book_service.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository_impl.dart';
import '../../infrastructure/datasource/book_remote_datasource.dart';
import '../widgets/book_filters_sheet.dart';
import '../widgets/horizontal_book_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _service = BookService(BookRepositoryImpl(BookRemoteDataSource()));
  Timer? _debounce;
  String _query = '';
  late Future<List<Book>> _allBooksFuture;


  BookFilterOptions _filters = const BookFilterOptions();

  @override
  void initState() {
    super.initState();
    _allBooksFuture = _service.getAllBooks();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _query = _controller.text.trim();
      });
    });
  }

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
            // --- Header de búsqueda ---
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
              child: Text(
                'SEARCH BY TITLE OR AUTHOR',
                style: t.headlineMedium?.copyWith(
                  color: AppColors.softTeal,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search here…',
                  hintStyle: t.bodyMedium?.copyWith(color: Colors.black54),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                    const BorderSide(color: AppColors.accentGold, width: 1.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: AppColors.vibrantBlue, width: 1.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.search, color: AppColors.vibrantBlue),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 2, color: AppColors.lightGrey),
            const SizedBox(height: 16),
            // --- Encabezado de resultados ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  Text(
                    'RESULTS',
                    style: t.bodyLarge?.copyWith(
                      color: AppColors.primaryOrange,
                      letterSpacing: 1.2,
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

            const SizedBox(height: 8),

            Expanded(
              child: FutureBuilder<List<Book>>(
                future: _allBooksFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }

                  final all = snap.data ?? const <Book>[];

                  // filtrar por query
                  var results = _query.isEmpty
                      ? <Book>[]
                      : all.where((b) {
                    final q = _query.toLowerCase();
                    return b.title.toLowerCase().contains(q) ||
                        b.author.toLowerCase().contains(q);
                  }).toList();

                  // aplicar filtros
                  results = _filters.apply(results);

                  if (_query.isNotEmpty && results.isEmpty) {
                    return Center(
                      child: Text(
                        'No results for “$_query”.',
                        style: t.bodyMedium,
                      ),
                    );
                  }


                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 8),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.8,
                    ),
                    itemCount: results.length,
                    itemBuilder: (_, i) =>
                        HorizontalBookCard(results[i], t),
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
