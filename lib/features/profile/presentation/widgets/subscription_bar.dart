import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../common/theme/app_colors.dart';
import '../providers/profile_provider.dart';

class SubscriptionBar extends StatelessWidget {
  final String currentPlan;
  final DateTime? planChangeDate;
  final bool hasPayed;

  const SubscriptionBar({
    super.key,
    required this.currentPlan,
    this.planChangeDate,
    this.hasPayed = false,
  });

  @override
  Widget build(BuildContext context) {
    final isCommunity = currentPlan.toLowerCase().contains('community');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.lightGrey, width: 1),
          bottom: BorderSide(color: AppColors.lightGrey, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("SUBSCRIPTION",
                      style: TextStyle(
                          color: AppColors.secondaryYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                  Text(
                    isCommunity ? "Community Plan" : "Free Plan",
                    style: const TextStyle(
                        color: AppColors.vibrantBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 16),
                  ),
                ],
              ),
              if (isCommunity)
                TextButton(
                  onPressed: () => _showLeaveDialog(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text("LEAVE PLAN",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                )
              else
                ElevatedButton(
                  onPressed: () => context.push('/profile/subscription'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softTeal,
                    foregroundColor: AppColors.darkBlue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text("UPGRADE",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
            ],
          ),

          // --- INFO EXTRA SOLO SI ES COMMUNITY ---
          if (isCommunity) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.lightGrey),
            const SizedBox(height: 10),

            // Fecha de inicio del plan
            if (planChangeDate != null)
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 14, color: AppColors.darkBlue),
                  const SizedBox(width: 6),
                  Text(
                    "Member since: ${DateFormat('dd/MM/yyyy').format(planChangeDate!)}",
                    style: const TextStyle(
                        color: AppColors.darkBlue, fontSize: 13),
                  ),
                ],
              ),

            const SizedBox(height: 6),

            // Estado de pago
            Row(
              children: [
                Icon(
                  hasPayed ? Icons.check_circle : Icons.warning_amber_rounded,
                  size: 14,
                  color: hasPayed ? Colors.green : AppColors.primaryOrange,
                ),
                const SizedBox(width: 6),
                Text(
                  hasPayed ? "Payment up to date" : "Payment pending",
                  style: TextStyle(
                    color: hasPayed ? Colors.green : AppColors.primaryOrange,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Botón de pago mensual
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/profile/subscription'),
                icon: const Icon(Icons.upload_outlined, size: 16),
                label: const Text("UPLOAD PAYMENT PROOF",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.vibrantBlue,
                  side: const BorderSide(color: AppColors.vibrantBlue),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Leave Community Plan?"),
        content: const Text(
          "Are you sure? Your membership will remain active for 2 more weeks and then terminate. You will lose access to premium features.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context
                  .read<ProfileProvider>()
                  .changeSubscriptionPlan("freeplan");
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("You have canceled your subscription."),
                      backgroundColor: Colors.grey),
                );
              }
            },
            child: const Text("Confirm Leave",
                style:
                TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}