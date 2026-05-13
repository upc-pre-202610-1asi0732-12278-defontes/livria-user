// lib/features/book/infrastructure/datasource/book_remote_datasource.dart
import 'package:http/http.dart' as http;
import 'package:livria_user/common/config/env.dart';

class BookRemoteDataSource {
  static final String _base = Env.apiBase;
  static const String _booksPath = '/api/v1/books';

  final http.Client _client;
  BookRemoteDataSource({http.Client? client}) : _client = client ?? http.Client();

  Future<http.Response> getAllBooks() {
    final uri = Uri.parse('$_base$_booksPath');
    return _client.get(uri);
  }

  Future<http.Response> getBook(int id) {
    final uri = Uri.parse('$_base$_booksPath/$id');
    return _client.get(uri);
  }
}
