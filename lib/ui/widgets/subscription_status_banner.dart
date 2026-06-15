import 'package:flutter/material.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/subscription_status.dart';
import 'package:sint/sint.dart';

import '../theme/app_color.dart';
import 'paywall_sheet.dart';

/// Surfaces the user's subscription/trial status with a clear "Continuar" CTA
/// when a trial or plan is about to expire (or already did) — the moment that
/// most drives trial → paid conversion. Renders nothing when there's no risk.
///
/// Drop it at the top of Home or Settings:
/// ```dart
/// const SubscriptionStatusBanner(),
/// ```
class SubscriptionStatusBanner extends StatelessWidget {
  /// Show the banner this many days before expiry. Trials always show.
  final int warnWithinDays;
  const SubscriptionStatusBanner({super.key, this.warnWithinDays = 7});

  @override
  Widget build(BuildContext context) {
    final sub = _currentSubscription();
    if (sub == null) return const SizedBox.shrink();

    final status = sub.status;
    final now = DateTime.now().millisecondsSinceEpoch;
    final daysLeft = sub.endDate > 0
        ? ((sub.endDate - now) / 86400000).ceil()
        : -1;

    final isTrial = status == SubscriptionStatus.trial;
    final isExpired = status == SubscriptionStatus.expired ||
        (sub.endDate > 0 && sub.endDate < now);
    final isExpiringSoon = sub.endDate > 0 && daysLeft >= 0 && daysLeft <= warnWithinDays;

    // Nothing worth nudging about → render nothing.
    if (!isTrial && !isExpired && !isExpiringSoon) return const SizedBox.shrink();

    final Color accent = isExpired
        ? const Color(0xFFF87171)
        : (isTrial ? AppColor.getMain() : const Color(0xFFFB923C));

    final String title;
    final String cta;
    if (isExpired) {
      title = 'Tu plan venció. Continúa para no perder tus beneficios.';
      cta = 'Reactivar';
    } else if (isTrial) {
      title = daysLeft >= 0
          ? 'Tu prueba termina en $daysLeft ${daysLeft == 1 ? "día" : "días"}. Continúa con tu plan.'
          : 'Estás en prueba. Continúa con tu plan cuando quieras.';
      cta = 'Continuar';
    } else {
      title = 'Tu plan vence en $daysLeft ${daysLeft == 1 ? "día" : "días"}.';
      cta = 'Renovar';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(children: [
        Icon(isExpired ? Icons.lock_clock : Icons.workspace_premium, color: accent, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: TextStyle(color: AppColor.textPrimary, fontSize: 13)),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: const Size(0, 0),
          ),
          onPressed: () {
            if (isExpired) {
              PaywallSheet.show(context, feature: 'Reactiva tu plan');
            } else {
              Sint.toNamed(AppRouteConstants.subscriptionPlans);
            }
          },
          child: Text(cta, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  dynamic _currentSubscription() {
    try {
      if (!Sint.isRegistered<UserService>()) return null;
      return Sint.find<UserService>().userSubscription;
    } catch (_) {
      return null;
    }
  }
}
