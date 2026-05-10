
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';

class ReviewService {
  final ReviewRepository _repos;
  const ReviewService(this._repos);

  Future<List<Review>> getAllReviews() => _repos.getAll();

  Future<List<Review>> getBookReviews(int id) => _repos.getBookReviews(id);

  Future<void> postReview({
    required int bookId,
    required String content,
    required int stars,
  }) => _repos.postReview(
    bookId: bookId,
    content: content,
    stars: stars,
  );

}
