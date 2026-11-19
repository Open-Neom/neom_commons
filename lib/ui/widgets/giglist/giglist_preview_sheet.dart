import 'dart:async';

import 'package:flutter/material.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/use_cases/audio_player_invoker_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import '../../theme/app_color.dart';
import '../../../utils/external_utilities.dart';
import '../custom_image.dart';
import '../rating_heart_bar.dart';
import 'youtube_preview_embed.dart';

/// Strictly preview-only (30-second max) reference sheet for YouTube Music
/// songs inside a Giglist.
///
/// Giglists are musician connection & repertoire lists — NEVER full-song
/// streaming playlists inside Gigmeout. This sheet:
/// 1. Pauses any active Gig Music playback and NEVER touches the audio queue.
/// 2. Mounts an official YouTube IFrame embed constrained to a 30s snippet.
/// 3. Automatically unmounts the embed at 0s so playback cannot continue.
/// 4. Surfaces musician connection CTAs (Songmates match, mastery level,
///    external YouTube Music reference).
class GiglistPreviewSheet extends StatefulWidget {
  final ExternalItem item;
  final int previewDurationSeconds;
  final VoidCallback? onAddToGiglist;
  final VoidCallback? onEditMastery;

  const GiglistPreviewSheet({
    super.key,
    required this.item,
    this.previewDurationSeconds = 30,
    this.onAddToGiglist,
    this.onEditMastery,
  });

  static Future<void> show(
    BuildContext context, {
    required ExternalItem item,
    int previewDurationSeconds = 30,
    VoidCallback? onAddToGiglist,
    VoidCallback? onEditMastery,
  }) async {
    // Pause any active Gig Music stream before starting a repertoire preview,
    // without enqueueing the YouTube reference into the audio player.
    try {
      if (Sint.isRegistered<AudioPlayerInvokerService>()) {
        await Sint.find<AudioPlayerInvokerService>().pause();
      }
    } catch (_) {}

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => GiglistPreviewSheet(
        item: item,
        previewDurationSeconds: previewDurationSeconds,
        onAddToGiglist: onAddToGiglist,
        onEditMastery: onEditMastery,
      ),
    );
  }

  @override
  State<GiglistPreviewSheet> createState() => _GiglistPreviewSheetState();
}

class _GiglistPreviewSheetState extends State<GiglistPreviewSheet> {
  Timer? _countdownTimer;
  late int _remainingSeconds;
  bool _previewActive = true;
  int _embedRunCounter = 0;

  String get _videoId {
    final fromId = extractYoutubeVideoId(widget.item.id);
    if (fromId.isNotEmpty) return fromId;
    return extractYoutubeVideoId(widget.item.permaUrl);
  }

  int get _startSeconds {
    final dur = widget.item.duration;
    if (dur > 0 && dur < 65) return 0;
    return 30;
  }

  @override
  void initState() {
    super.initState();
    _startPreviewTimer();
  }

  void _startPreviewTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _remainingSeconds = widget.previewDurationSeconds.clamp(5, 30);
      _previewActive = _videoId.isNotEmpty;
      _embedRunCounter++;
    });

    if (!_previewActive) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _previewActive = false;
        });
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _stopPreview() {
    _countdownTimer?.cancel();
    setState(() {
      _previewActive = false;
      _remainingSeconds = 0;
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.previewDurationSeconds.clamp(5, 30);
    final progress = total > 0 ? (total - _remainingSeconds) / total : 1.0;
    final videoId = _videoId;
    final ytUrl = widget.item.permaUrl.isNotEmpty
        ? widget.item.permaUrl
        : (videoId.isNotEmpty ? 'https://music.youtube.com/watch?v=$videoId' : '');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Badge clarifying preview-only semantics
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _previewActive
                          ? 'Preview de conexión · ${_remainingSeconds}s restantes'
                          : 'Solo preview (${total}s) · Repertorio Giglist',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Song metadata header
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.item.imgUrl.isNotEmpty
                        ? platformNetworkImage(
                            imageUrl: widget.item.imgUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 52,
                            height: 52,
                            color: AppColor.getMain().withValues(alpha: 0.3),
                            child: const Icon(
                              Icons.music_note_rounded,
                              color: Colors.white70,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${widget.item.ownerName} · YouTube Music',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.item.state > 0) ...[
                              const SizedBox(width: 8),
                              RatingHeartBar(
                                state: widget.item.state.toDouble(),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Official YouTube IFrame embed (unmounted cleanly when timer expires)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    color: Colors.black,
                    child: _previewActive && videoId.isNotEmpty
                        ? KeyedSubtree(
                            key: ValueKey('yt-preview-$videoId-$_embedRunCounter'),
                            child: buildYoutubePreviewEmbed(
                              videoId: videoId,
                              startSeconds: _startSeconds,
                              previewSeconds: total,
                              fallbackImgUrl: widget.item.imgUrl,
                            ),
                          )
                        : _buildStoppedOverlay(
                            context,
                            hasVideo: videoId.isNotEmpty,
                            totalSeconds: total,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 30-second preview progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColor.getMain()),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Las Giglists son listas de repertorio para conectar con músicos y bandas. '
                'Las canciones de YouTube Music no se streamean completas en Gigmeout.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_previewActive)
                    OutlinedButton.icon(
                      onPressed: _stopPreview,
                      icon: const Icon(Icons.stop_circle_outlined, size: 18),
                      label: const Text('Detener preview'),
                    )
                  else if (videoId.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: _startPreviewTimer,
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: Text('Repetir preview (${total}s)'),
                    ),
                  if (widget.onAddToGiglist != null)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColor.getMain(),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onAddToGiglist!();
                      },
                      icon: const Icon(Icons.playlist_add_rounded, size: 18),
                      label: const Text('Agregar a Giglist'),
                    ),
                  if (widget.onEditMastery != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onEditMastery!();
                      },
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Nivel de dominio'),
                    ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Sint.toNamed(AppRouteConstants.mates);
                    },
                    icon: const Icon(Icons.people_alt_outlined, size: 18),
                    label: const Text('Ver Songmates'),
                  ),
                  if (ytUrl.isNotEmpty)
                    TextButton.icon(
                      onPressed: () =>
                          ExternalUtilities.launchURL(ytUrl, sameTab: false),
                      icon: const Icon(
                        Icons.open_in_new_rounded,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      label: const Text(
                        'YouTube Music',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoppedOverlay(
    BuildContext context, {
    required bool hasVideo,
    required int totalSeconds,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.item.imgUrl.isNotEmpty)
          platformNetworkImage(
            imageUrl: widget.item.imgUrl,
            fit: BoxFit.cover,
          ),
        Container(
          color: Colors.black.withValues(alpha: 0.72),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasVideo ? Icons.check_circle_outline : Icons.info_outline,
                color: Colors.white70,
                size: 38,
              ),
              const SizedBox(height: 8),
              Text(
                hasVideo
                    ? 'Preview de ${totalSeconds}s finalizado'
                    : 'Sin video de referencia disponible',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              const Text(
                'Agrega esta canción a tu Giglist para hacer match con otros músicos.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
