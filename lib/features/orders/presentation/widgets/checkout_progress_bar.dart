import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../common/theme/app_colors.dart';

class CheckoutProgressBar extends StatelessWidget {
  final int currentStep;

  const CheckoutProgressBar({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepIcon(
          context,
          1,
          Icon(Icons.person, color: _iconColor(context, 1), size: 20),
        ),
        const SizedBox(width: 15),
        _buildStepIcon(
          context,
          2,
          FaIcon(FontAwesomeIcons.box, color: _iconColor(context, 2), size: 20),
        ),
        const SizedBox(width: 15),
        _buildStepIcon(
          context,
          3,
          Icon(Icons.credit_card, color: _iconColor(context, 3), size: 20),
        ),
      ],
    );
  }

  Color _iconColor(BuildContext context, int stepIndex) {
    final bool isActive = stepIndex == currentStep;
    return isActive ? AppColors.white : AppColors.darkBlue;
  }

  Widget _buildStepIcon(BuildContext context, int stepIndex, Widget icon) {
    final bool isActive = stepIndex == currentStep;

    final color = isActive ? AppColors.darkBlue : AppColors.secondaryYellow;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(child: icon),
    );
  }
}