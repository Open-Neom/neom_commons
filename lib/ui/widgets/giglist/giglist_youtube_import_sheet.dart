import 'package:flutter/material.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/data/api/app_accounts.dart';
import 'package:neom_core/data/firestore/itemlist_firestore.dart';
import 'package:neom_core/domain/model/external_item.dart';
import 'package:neom_core/domain/model/item_list.dart';
import 'package:neom_core/domain/use_cases/external_music_service.dart';
import 'package:neom_core/domain/use_cases/user_service.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:neom_core/utils/enums/app_item_state.dart';
import 'package:neom_core/utils/enums/itemlist_type.dart';
import 'package:neom_core/utils/enums/owner_type.dart';
import 'package:sint/sint.dart';

import '../../theme/app_color.dart';
import '../../../utils/app_utilities.dart';
import '../../../utils/auth_guard.dart';
import '../custom_image.dart';
import 'giglist_preview_sheet.dart';

/// Bulk-imports a public YouTube / YouTube Music playlist into a Giglist
/// (`ItemlistType.giglist`) so musicians can migrate their repertoire in seconds
/// instead of adding songs one by one.
class GiglistYoutubeImportSheet extends StatefulWidget {
  final Itemlist? targetGiglist;
  final OwnerType ownerType;
  final void Function(Itemlist importedGiglist)? onImported;

  const GiglistYoutubeImportSheet({
    super.key,
    this.targetGiglist,
    this.ownerType = OwnerType.profile,
    this.onImported,
  });

  static Future<Itemlist?> show(
    BuildContext context, {
    Itemlist? targetGiglist,
    OwnerType ownerType = OwnerType.profile,
    void Function(Itemlist importedGiglist)? onImported,
  }) async {
    if (!AppConfig.instance.canPersistUserActivity) {
      AuthGuard.protect(
        context,
        () => show(
          context,
          targetGiglist: targetGiglist,
          ownerType: ownerType,
          onImported: onImported,
        ),
      );
      return null;
    }

    return showModalBottomSheet<Itemlist?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColor.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => GiglistYoutubeImportSheet(
          targetGiglist: targetGiglist,
          ownerType: ownerType,
          onImported: onImported,
        ),
      ),
    );
  }

  @override
  State<GiglistYoutubeImportSheet> createState() =>
      _GiglistYoutubeImportSheetState();
}

class _GiglistYoutubeImportSheetState extends State<GiglistYoutubeImportSheet> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _playlistSearchController =
      TextEditingController();
  final TextEditingController _newGiglistNameController =
      TextEditingController();

  int _mode = 0; // 0 = Paste URL / ID, 1 = Search public YT Music playlists
  bool _isLoading = false;
  bool _isImporting = false;
  String? _errorMsg;

  List<Itemlist> _foundPlaylists = [];
  ExternalPlaylistImportResult? _loadedPlaylist;
  final Set<String> _selectedSongIds = <String>{};
  int _defaultMastery = AppItemState.readyToPlay.value; // 5

  List<Itemlist> _existingGiglists = [];
  String? _selectedExistingGiglistId; // null => create new Giglist

  @override
  void initState() {
    super.initState();
    _loadExistingGiglists();
  }

  Future<void> _loadExistingGiglists() async {
    try {
      final userService = Sint.find<UserService>();
      final isCollective = widget.ownerType == OwnerType.collective;
      final ownerId =
          isCollective ? userService.collective.id : userService.profile.id;
      if (ownerId.isEmpty) return;

      final cached = isCollective
          ? (userService.collective.itemlists ?? {})
          : (userService.profile.itemlists ?? {});
      var giglists = cached.values
          .where((l) => l.type == ItemlistType.giglist && l.isModifiable)
          .toList();
      if (giglists.isEmpty) {
        final fetched = await ItemlistFirestore().getByOwnerId(
          ownerId,
          ownerType: widget.ownerType,
          itemlistType: ItemlistType.giglist,
        );
        giglists = fetched.values.where((l) => l.isModifiable).toList();
      }
      if (!mounted) return;
      setState(() {
        _existingGiglists = giglists;
        if (widget.targetGiglist != null &&
            widget.targetGiglist!.type == ItemlistType.giglist &&
            widget.targetGiglist!.id.isNotEmpty) {
          _selectedExistingGiglistId = widget.targetGiglist!.id;
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _urlController.dispose();
    _playlistSearchController.dispose();
    _newGiglistNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchByUrlOrId(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      setState(() => _errorMsg = 'Pega el enlace o ID de una playlist pública de YouTube / YouTube Music.');
      return;
    }
    if (!Sint.isRegistered<ExternalMusicService>()) {
      setState(() => _errorMsg = 'El servicio de YouTube Music no está disponible.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _loadedPlaylist = null;
      _selectedSongIds.clear();
    });

    try {
      final result = await Sint.find<ExternalMusicService>().fetchPlaylistItems(
        trimmed,
        maxResults: 100,
      );
      if (!mounted) return;
      if (!result.hasSongs) {
        setState(() {
          _isLoading = false;
          _errorMsg = result.error ??
              'No se encontraron canciones. Verifica que la playlist de YouTube sea pública o no listada.';
        });
        return;
      }

      setState(() {
        _loadedPlaylist = result;
        _selectedSongIds.addAll(result.songs.map((s) => s.id));
        if (_newGiglistNameController.text.trim().isEmpty) {
          _newGiglistNameController.text =
              result.title.isNotEmpty ? result.title : 'Mi Giglist Importada';
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = 'Error al leer la playlist de YouTube: $e';
      });
    }
  }

  Future<void> _searchPublicPlaylists() async {
    final query = _playlistSearchController.text.trim();
    if (query.length < 2) {
      setState(() => _errorMsg = 'Escribe al menos 2 caracteres para buscar playlists públicas.');
      return;
    }
    if (!Sint.isRegistered<ExternalMusicService>()) {
      setState(() => _errorMsg = 'El servicio de YouTube Music no está disponible.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _foundPlaylists = [];
    });

    try {
      final playlists =
          await Sint.find<ExternalMusicService>().searchAlbums(query);
      if (!mounted) return;
      setState(() {
        _foundPlaylists = playlists;
        _isLoading = false;
        if (playlists.isEmpty) {
          _errorMsg = 'No se encontraron playlists públicas para "$query".';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = 'No se pudo buscar playlists en YouTube Music.';
      });
    }
  }

  Future<void> _importSelectedSongs() async {
    final loaded = _loadedPlaylist;
    if (loaded == null || _selectedSongIds.isEmpty || _isImporting) return;

    setState(() {
      _isImporting = true;
      _errorMsg = null;
    });

    try {
      final userService = Sint.find<UserService>();
      final isCollective = widget.ownerType == OwnerType.collective;
      final ownerId =
          isCollective ? userService.collective.id : userService.profile.id;
      final ownerName =
          isCollective ? userService.collective.name : userService.profile.name;

      final selectedSongs = loaded.songs
          .where((s) => _selectedSongIds.contains(s.id))
          .map(
            (s) => ExternalItem(
              id: s.id,
              name: s.name,
              ownerName: s.ownerName,
              ownerId: s.ownerId,
              album: s.album,
              duration: s.duration,
              description: s.description,
              imgUrl: s.imgUrl,
              galleryUrls: s.galleryUrls,
              url: '', // Strictly never streamable in Gigmeout
              permaUrl: s.permaUrl,
              source: s.source,
              type: s.type,
              publishedYear: s.publishedYear,
              state: _defaultMastery,
            ),
          )
          .toList();

      final repo = ItemlistFirestore();
      Itemlist? target;

      if (_selectedExistingGiglistId != null &&
          _selectedExistingGiglistId!.isNotEmpty) {
        target = _existingGiglists
            .where((g) => g.id == _selectedExistingGiglistId)
            .firstOrNull;
        target ??= widget.targetGiglist;
      }

      if (target == null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final name = _newGiglistNameController.text.trim().isNotEmpty
            ? _newGiglistNameController.text.trim()
            : (loaded.title.isNotEmpty ? loaded.title : 'Mi Giglist');
        final created = Itemlist(
          name: name,
          description: loaded.description.isNotEmpty
              ? loaded.description
              : 'Repertorio importado de YouTube Music para conectar con músicos',
          ownerId: ownerId,
          ownerName: ownerName,
          ownerType: widget.ownerType,
          imgUrl: loaded.imgUrl.isNotEmpty
              ? loaded.imgUrl
              : selectedSongs.first.imgUrl,
          type: ItemlistType.giglist,
          public: true,
          isModifiable: true,
          externalItems: selectedSongs,
          createdTime: now,
          modifiedTime: now,
        );
        final newId = await repo.insert(created);
        if (newId.isEmpty) {
          throw StateError('No se pudo crear la Giglist en Firestore.');
        }
        created.id = newId;
        target = created;
      } else {
        await repo.addExternalItemsBulk(target.id, selectedSongs);
        target.externalItems ??= [];
        final byId = <String, ExternalItem>{
          for (final existing in target.externalItems!) existing.id: existing,
        };
        for (final song in selectedSongs) {
          byId[song.id] = song;
        }
        target.externalItems = byId.values.toList();
      }

      // Sync in-memory owner itemlists & profile favoriteItems for instant matching
      if (isCollective) {
        userService.collective.itemlists ??= {};
        userService.collective.itemlists![target.id] = target;
      } else {
        userService.profile.itemlists ??= {};
        userService.profile.itemlists![target.id] = target;
        userService.profile.favoriteItems ??= [];
        for (final song in selectedSongs) {
          if (!userService.profile.favoriteItems!.contains(song.id)) {
            userService.profile.favoriteItems!.add(song.id);
          }
        }
        try {
          await AppProfiles.repository.addFavoriteItems(
            ownerId,
            selectedSongs.map((s) => s.id).toList(),
          );
        } catch (_) {
          // Fallback to per-item only for first few if batch helper fails
        }
      }

      widget.onImported?.call(target);
      if (!mounted) return;
      Navigator.of(context).pop(target);
      AppUtilities.showSnackBar(
        title: 'Giglist lista (${selectedSongs.length} canciones)',
        message:
            'Se importaron ${selectedSongs.length} canciones a "${target.name}" (solo preview para conectar con Songmates).',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isImporting = false;
        _errorMsg = 'No se pudo completar la importación: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
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
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.playlist_add_check_circle_outlined,
                  color: Colors.redAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Importar Playlist de YouTube a Giglist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(
              'Migra tu repertorio en segundos. Las canciones importadas solo ofrecen preview de 30s para conectar con músicos y bandas.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),

            // Mode selector
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.link_rounded, size: 16),
                  label: Text('Pegar enlace / ID'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.search_rounded, size: 16),
                  label: Text('Buscar playlists'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() {
                  _mode = selection.first;
                  _errorMsg = null;
                });
              },
            ),
            const SizedBox(height: 12),

            if (_mode == 0) _buildUrlInput() else _buildPlaylistSearchInput(),

            if (_errorMsg != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _loadedPlaylist != null
                      ? _buildLoadedSongsSection()
                      : _mode == 1 && _foundPlaylists.isNotEmpty
                          ? _buildFoundPlaylistsList()
                          : _buildInstructionsCard(),
            ),

            if (_loadedPlaylist != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.getMain(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isImporting || _selectedSongIds.isEmpty
                      ? null
                      : _importSelectedSongs,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_download_outlined),
                  label: Text(
                    _isImporting
                        ? 'Importando repertorio...'
                        : 'Importar ${_selectedSongIds.length} canciones a Giglist',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUrlInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'https://music.youtube.com/playlist?list=PL...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onSubmitted: _fetchByUrlOrId,
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColor.getMain(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onPressed: _isLoading
              ? null
              : () => _fetchByUrlOrId(_urlController.text),
          child: const Text('Cargar'),
        ),
      ],
    );
  }

  Widget _buildPlaylistSearchInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _playlistSearchController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Ej. Rock en Español 90s, Jazz Standards, Covers...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            onSubmitted: (_) => _searchPublicPlaylists(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColor.getMain(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onPressed: _isLoading ? null : _searchPublicPlaylists,
          child: const Text('Buscar'),
        ),
      ],
    );
  }

  Widget _buildFoundPlaylistsList() {
    return ListView.separated(
      itemCount: _foundPlaylists.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
      itemBuilder: (context, index) {
        final pl = _foundPlaylists[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: pl.imgUrl.isNotEmpty
                ? platformNetworkImage(
                    imageUrl: pl.imgUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: Colors.white10,
                    child: const Icon(Icons.queue_music, color: Colors.white54),
                  ),
          ),
          title: Text(
            pl.name,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            pl.ownerName,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
          onTap: () {
            _newGiglistNameController.text = pl.name;
            _fetchByUrlOrId(pl.id);
          },
        );
      },
    );
  }

  Widget _buildLoadedSongsSection() {
    final loaded = _loadedPlaylist!;
    final allSelected = _selectedSongIds.length == loaded.songs.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Destination Giglist selector + mastery
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: _selectedExistingGiglistId,
                dropdownColor: AppColor.surfaceCard,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Destino',
                  labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                  filled: true,
                  fillColor: AppColor.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('+ Crear nueva Giglist'),
                  ),
                  ..._existingGiglists.map(
                    (g) => DropdownMenuItem<String?>(
                      value: g.id,
                      child: Text(
                        '${g.name} (${g.allItems.length})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) =>
                    setState(() => _selectedExistingGiglistId = val),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 148,
              child: DropdownButtonFormField<int>(
                initialValue: _defaultMastery,
                dropdownColor: AppColor.surfaceCard,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Dominio',
                  labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                  filled: true,
                  fillColor: AppColor.surfaceCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 · Interés')),
                  DropdownMenuItem(value: 2, child: Text('2 · Aprendiendo')),
                  DropdownMenuItem(value: 3, child: Text('3 · Ensayo')),
                  DropdownMenuItem(value: 4, child: Text('4 · En vivo')),
                  DropdownMenuItem(value: 5, child: Text('5 · Dominada')),
                ],
                onChanged: (v) => setState(() => _defaultMastery = v ?? 5),
              ),
            ),
          ],
        ),
        if (_selectedExistingGiglistId == null) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _newGiglistNameController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Nombre de la nueva Giglist',
              labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedSongIds.length} / ${loaded.songs.length} canciones seleccionadas',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  if (allSelected) {
                    _selectedSongIds.clear();
                  } else {
                    _selectedSongIds.addAll(loaded.songs.map((s) => s.id));
                  }
                });
              },
              child: Text(allSelected ? 'Deseleccionar todo' : 'Seleccionar todo'),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: loaded.songs.length,
            itemBuilder: (context, index) {
              final song = loaded.songs[index];
              final checked = _selectedSongIds.contains(song.id);
              return CheckboxListTile(
                value: checked,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColor.getMain(),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedSongIds.add(song.id);
                    } else {
                      _selectedSongIds.remove(song.id);
                    }
                  });
                },
                title: Text(
                  song.name,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.ownerName,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                secondary: IconButton(
                  tooltip: 'Preview 30s',
                  icon: const Icon(
                    Icons.ondemand_video_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () => GiglistPreviewSheet.show(
                    context,
                    item: song,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.library_music_outlined,
              color: Colors.redAccent,
              size: 40,
            ),
            const SizedBox(height: 10),
            const Text(
              'Migra tus playlists de YouTube Music a tu Giglist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '1. Abre tu playlist en YouTube o YouTube Music (pública o no listada).\n'
              '2. Copia el enlace y pégalo arriba (o búscala por nombre).\n'
              '3. Importa hasta 100 canciones de una sola vez para activar tu Match de Songmates.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Sint.toNamed(AppRouteConstants.mates);
              },
              icon: const Icon(Icons.people_outline, size: 16),
              label: const Text('Ver mis Songmates actuales'),
            ),
          ],
        ),
      ),
    );
  }
}
