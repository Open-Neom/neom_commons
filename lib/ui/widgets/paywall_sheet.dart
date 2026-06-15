import 'package:flutter/material.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import '../theme/app_color.dart';

/// Contextual paywall — show it at the exact moment a user hits a gated feature
/// (more obras, más almacenamiento, función Pro…) so the upgrade offer lands
/// where the need is, not in a generic menu.
///
/// Usage from any gate:
/// ```dart
/// if (!hasAccess) { PaywallSheet.show(context, feature: 'Publicar más obras'); return; }
/// ```
class PaywallSheet {
  PaywallSheet._();

  static Future<void> show(
    BuildContext context, {
    required String feature,
    String benefit = '',
    List<String> perks = const [],
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
        decoration: BoxDecoration(
          color: AppColor.scaffold,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColor.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: AppColor.getMain().withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.workspace_premium, color: AppColor.getMain(), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(feature,
                    style: TextStyle(color: AppColor.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              benefit.isNotEmpty
                  ? benefit
                  : 'Esta función es parte de un plan de suscripción. Mejora tu plan para desbloquearla y aprovechar todo el ecosistema.',
              style: TextStyle(color: AppColor.textSecondary, fontSize: 13, height: 1.4),
            ),
            if (perks.isNotEmpty) ...[
              const SizedBox(height: 14),
              ...perks.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Icon(Icons.check_circle, color: AppColor.getMain(), size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(p, style: TextStyle(color: AppColor.textSecondary, fontSize: 13))),
                    ]),
                  )),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.getMain(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Sint.toNamed(AppRouteConstants.subscriptionPlans);
                },
                child: const Text('Ver planes',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Ahora no', style: TextStyle(color: AppColor.textMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
