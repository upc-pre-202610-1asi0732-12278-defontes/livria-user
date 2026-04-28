import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:livria_user/common/widgets/main_shell.dart';
import 'package:livria_user/features/auth/presentation/pages/login_page.dart';
import 'package:livria_user/features/auth/presentation/pages/register_step1_page.dart';
import 'package:livria_user/features/auth/presentation/pages/register_step2_page.dart';
import 'package:livria_user/features/auth/presentation/pages/splash_page.dart';

import 'package:livria_user/features/book/presentation/pages/search_page.dart';
import 'package:livria_user/features/book/presentation/pages/recommendations_page.dart';
import 'package:livria_user/features/orders/presentation/pages/location_page.dart';

import 'package:livria_user/features/home/presentation/pages/home_page.dart';
import 'package:livria_user/features/book/presentation/pages/categories_page.dart';
import 'package:livria_user/features/book/presentation/pages/category_books_page.dart';
import 'package:livria_user/features/communities/presentation/pages/communities_page.dart';
import 'package:livria_user/features/profile/presentation/pages/profile_page.dart';

import '../../features/book/application/services/book_service.dart';
import '../../features/book/domain/entities/book.dart';
import '../../features/book/domain/repositories/book_repository_impl.dart';
import '../../features/book/infrastructure/datasource/book_remote_datasource.dart';
import '../../features/book/presentation/widgets/book_wraper.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/orders/presentation/pages/payment_page.dart';
import '../../features/orders/presentation/pages/recipient_info_page.dart';
import '../../features/orders/presentation/pages/shipping_info_page.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_local_datasource.dart';
import 'package:livria_user/features/auth/infrastructure/datasource/auth_remote_datasource.dart';

import '../../features/profile/presentation/pages/subscription_payment_page.dart';
import '../di/dependencies.dart' as di;

final appRouter = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage()
      ),
      GoRoute(
        path: '/register_step1',
        builder: (context, state) => const RegisterStep1Page(),
      ),
      GoRoute(
        path: '/register_step2',
        builder: (context, state) {
          final data = state.extra as Map<String, String>?;

          if (data == null) {
            return const RegisterStep1Page();
          }

          return RegisterStep2Page(
            email: data['email']!,
            password: data['password']!,
          );
        },
      ),

        ShellRoute(
            builder: (context, state, child) {
                return MainShell(child: child);
            },
            routes: [
              GoRoute(path: '/home', builder: (context, state) => HomePage(authLocalDataSource: di.authLocalDataSource, authRemoteDataSource: AuthRemoteDataSource(),)),
              GoRoute(path: '/categories', builder: (context, state) => const CategoriesPage()),
              GoRoute(
                path: '/categories/:genre',
                builder: (context, state) {
                  final genre = state.pathParameters['genre'] ?? '';
                  return CategoryBooksPage(genre: Uri.decodeComponent(genre));
                },
              ),
              GoRoute(
                path: '/book/:bookId',
                builder: (context, state) {
                  final bookId = state.pathParameters['bookId'] ?? '';

                  return BookLoadingWrapper(bookId: int.parse(bookId));
                },
              ),
                GoRoute(
                    path: '/communities',
                    builder: (context, state) => CommunitiesPage(
                      authLocalDataSource: di.authLocalDataSource,
                      authRemoteDataSource: AuthRemoteDataSource(),
                    )
                ),
                GoRoute(
                    path: '/notifications',
                    builder: (context, state) => const NotificationsPage()
                ),
                GoRoute(
                    path: '/profile',
                    builder: (context, state) => const ProfilePage()
                ),
                GoRoute(
                    path: '/search',
                    builder: (context, state) => const SearchPage()
                ),
                GoRoute(
                    path: '/recommendations',
                    builder: (context, state) => const RecommendationsPage()
                ),
                GoRoute(
                  path: '/profile/subscription',
                  builder: (context, state) => const SubscriptionPaymentPage(),
                ),
                GoRoute(
                    path: '/location',
                    builder: (context, state) => const LocationPage()
                ),
                GoRoute(
                  path: '/checkout/shipping',
                  builder: (context, state) => const ShippingInfoPage(),
                ),
                GoRoute(
                    path: '/cart',
                    builder: (context, state) => const CartPage()
                ),
              GoRoute(
                path: '/checkout/recipient',
                builder: (context, state) => const RecipientInfoPage(),
              ),
              GoRoute(
                path: '/checkout/payment',
                builder: (context, state) => const PaymentPage(),
              ),
              GoRoute(
                path: '/checkout/confirmation',
                builder: (context, state) => const Scaffold(body: Center(child: Text("Thanks for your purchase! 🎉"))),
              ),
            ],
        ),
    ]
);
