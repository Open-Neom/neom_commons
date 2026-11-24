import 'package:flutter/material.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/domain/use_cases/founding_service.dart';
import 'package:neom_core/utils/enums/app_in_use.dart';
import 'package:sint/sint.dart';

import '../theme/app_color.dart';

/// Displays live EMXI Fondeos campaign progress on the creator's profile
/// (`neom_profile`) and on public author profiles (`neom_mates`) without
/// creating a direct package dependency on `neom_founding`.
class ProfileFoundingProgressSection extends StatefulWidget {
  const ProfileFoundingProgressSection({
    super.key,
    required this.ownerUid,
    this.isOwner = false,
    this.compact = false,
  });

  final String ownerUid;
  final bool isOwner;
  final bool compact;

  @override
  State<ProfileFoundingProgressSection> createState() =>
      _ProfileFoundingProgressSectionState();
}

class _ProfileFoundingProgressSectionState
    extends State<ProfileFoundingProgressSection> {
  Future<List<FoundingProfileCampaignSummary>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfileFoundingProgressSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerUid != widget.ownerUid ||
        oldWidget.isOwner != widget.isOwner) {
      _load();
    }
  }

  void _load() {
    if (AppConfig.instance.appInUse != AppInUse.e ||
        widget.ownerUid.trim().isEmpty ||
        !Sint.isRegistered<FoundingService>()) {
      _future = null;
      return;
    }
    _future = Sint.find<FoundingService>().getProfileCampaignSummaries(
      ownerUid: widget.ownerUid,
      includePrivate: widget.isOwner,
    );
  }

  String _formatMxn(double value) {
    final str = value.round().abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buf.write(',');
      buf.write(str[i]);
    }
    return '\$${buf.toString()} MXN';
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) return const SizedBox.shrink();

    return FutureBuilder<List<FoundingProfileCampaignSummary>>(
      future: future,
      builder: (context, snapshot) {
        final items = snapshot.data;
        if (items == null || items.isEmpty) return const SizedBox.shrink();

        final mainColor = AppColor.getMain();
        final accentColor = AppColor.getAccentColor();

        return Container(
          key: const ValueKey('profile-founding-progress-section'),
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: EdgeInsets.all(widget.compact ? 12 : 16),
          decoration: BoxDecoration(
            color: AppColor.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.rocket_launch_rounded, color: accentColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isOwner
                          ? 'Avance de tus campañas EMXI Fondeos'
                          : 'Campaña activa en EMXI Fondeos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...items.map((c) => _buildCampaignCard(c, mainColor, accentColor)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCampaignCard(
    FoundingProfileCampaignSummary c,
    Color mainColor,
    Color accentColor,
  ) {
    return Container(
      key: ValueKey('profile-founding-card-${c.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.borderMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  c.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mainColor.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.55)),
                ),
                child: Text(
                  c.statusLabelEs,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_formatMxn(c.currentAmount)} de ${_formatMxn(c.goalAmount)} · ${c.progressPercent}%',
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: c.progressRatio,
              minHeight: 7,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reto 50 lectores: ${c.backerCount} / 50',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${c.daysRemaining} días rest.',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          if (widget.isOwner) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.support_agent_rounded, size: 14, color: accentColor),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    c.assignedResponsibleName.isNotEmpty
                        ? 'Responsable EMXI: ${c.assignedResponsibleName}'
                        : 'Responsable EMXI: Por asignar',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
            if (c.staffStatusNote.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Nota EMXI: ${c.staffStatusNote}',
                style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 11,
                ),
              ),
            ],
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (c.slug.isNotEmpty)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white30),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () =>
                      Sint.find<FoundingService>().openCampaignDetail(c.slug),
                  child: Text(widget.isOwner ? 'Ver campaña' : 'Apoyar obra'),
                ),
              if (widget.isOwner)
                ElevatedButton.icon(
                  key: ValueKey('profile-open-dashboard-${c.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => Sint.find<FoundingService>()
                      .openCreatorDashboard(campaignId: c.id),
                  icon: const Icon(Icons.forum_outlined, size: 14),
                  label: const Text('Panel y Chat EMXI'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
