import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/animated_balance.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../router/route_names.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final String rfid;

  const BalanceCard({super.key, required this.balance, required this.rfid});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.28),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Decorative bolt
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.bolt_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Saldo Anda',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75))),
                  const Spacer(),
                  Pressable(
                    onTap: () => context.go(RouteNames.topupRequest),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward_rounded,
                              size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Top Up',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBalance(
                value: balance,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'RFID · $rfid',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.credit_card_rounded,
                      size: 20, color: Colors.white.withValues(alpha: 0.75)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
