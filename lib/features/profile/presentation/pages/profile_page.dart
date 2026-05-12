import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../common/theme/app_colors.dart';
import '../providers/profile_provider.dart';

import '../widgets/my_communities_tab.dart';
import '../widgets/profile_header.dart';
import '../widgets/subscription_bar.dart';
import '../widgets/my_orders_tab.dart';
import '../widgets/edit_bio_tab.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadData();
    });
  }

  // Lógica de Logout
  Future<void> _handleLogout() async {
    final provider = context.read<ProfileProvider>();
    await provider.logout(); // Limpia shared preferences
    if (mounted) context.go('/login');
  }

  // Lógica de Borrar Cuenta
  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure? This action cannot be undone and you will lose your order history."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await context.read<ProfileProvider>().deleteAccount(context);
      if (success && mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final user = provider.user;

    // ESTADO DE CARGA
    if (provider.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)),
      );
    }

    // ESTADO DE ERROR
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Failed to load profile"),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => provider.loadData(),
                child: const Text("Retry"),
              )
            ],
          ),
        ),
      );
    }

    // UI PRINCIPAL
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                child: ProfileHeader(user: user),
              ),

              // BARRA DE SUSCRIPCIÓN (CORREGIDA)
              SubscriptionBar(currentPlan: user.subscription),

              const SizedBox(height: 20),

              // PESTAÑAS (TABS)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTabButton(
                        context,
                        label: "MY ORDERS",
                        index: 0,
                        isSelected: provider.selectedTab == 0
                    ),
                    _buildTabButton(
                        context,
                        label: "EDIT BIO",
                        index: 1,
                        isSelected: provider.selectedTab == 1
                    ),
                    _buildTabButton(
                        context,
                        label: "MY COMMUNITIES",
                        index: 2,
                        isSelected: provider.selectedTab == 2
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: provider.selectedTab == 0
                    ? const MyOrdersTab()
                    : (provider.selectedTab == 1 ? const EditBioTab(): MyCommunitiesTab()),
              ),

              const SizedBox(height: 50),

              // BOTONES INFERIORES
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón Delete Account
                    ElevatedButton(
                      onPressed: _handleDeleteAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.softTeal,
                        foregroundColor: AppColors.vibrantBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: const Text("DELETE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),

                    // Botón Log Out
                    ElevatedButton(
                      onPressed: _handleLogout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text("LOG OUT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, {required String label, required int index, required bool isSelected}) {
    return InkWell(
      onTap: () => context.read<ProfileProvider>().changeTab(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: isSelected
            ? BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.vibrantBlue, width: 3))
        )
            : null,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.vibrantBlue : Colors.grey,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}