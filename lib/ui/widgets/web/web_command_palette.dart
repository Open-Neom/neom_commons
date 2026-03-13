import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neom_core/utils/constants/app_route_constants.dart';
import 'package:sint/sint.dart';

import '../../theme/app_color.dart';

/// A single command entry in the palette.
class CommandPaletteItem {
  final String id;
  final String label;
  final String section;
  final IconData icon;
  final VoidCallback onSelect;
  final List<String> keywords;

  const CommandPaletteItem({
    required this.id,
    required this.label,
    required this.section,
    required this.icon,
    required this.onSelect,
    this.keywords = const [],
  });
}

/// VS Code / Notion-style command palette opened with Ctrl+K.
class WebCommandPalette extends StatefulWidget {
  const WebCommandPalette({super.key});

  /// Shows the command palette as a dialog.
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(120),
      builder: (_) => const WebCommandPalette(),
    );
  }

  @override
  State<WebCommandPalette> createState() => _WebCommandPaletteState();
}

class _WebCommandPaletteState extends State<WebCommandPalette> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  int _selectedIndex = 0;
  String _query = '';

  late final List<CommandPaletteItem> _allItems;

  @override
  void initState() {
    super.initState();
    _allItems = _buildDefaultCommands();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<CommandPaletteItem> get _filteredItems {
    if (_query.isEmpty) return _allItems;
    final q = _query.toLowerCase();
    return _allItems.where((item) {
      return item.label.toLowerCase().contains(q) ||
          item.keywords.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          setState(() => _selectedIndex = (_selectedIndex + 1).clamp(0, items.length - 1));
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() => _selectedIndex = (_selectedIndex - 1).clamp(0, items.length - 1));
        } else if (event.logicalKey == LogicalKeyboardKey.enter && items.isNotEmpty) {
          _executeItem(items[_selectedIndex]);
        } else if (event.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
        }
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 120),
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 560,
                constraints: const BoxConstraints(maxHeight: 420),
                decoration: BoxDecoration(
                  color: AppColor.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColor.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(80),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColor.surfaceDim,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search commands...',
                          hintStyle: TextStyle(color: AppColor.textMuted),
                          prefixIcon: Icon(Icons.search, color: AppColor.textSecondary),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _query = value;
                            _selectedIndex = 0;
                          });
                        },
                      ),
                    ),
                    Divider(height: 1, color: AppColor.borderSubtle),
                    // Results
                    Flexible(
                      child: items.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No results found',
                                style: TextStyle(color: AppColor.textMuted, fontSize: 14),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: items.length + _sectionHeaderCount(items),
                              itemBuilder: (context, index) =>
                                  _buildListItem(items, index),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _sectionHeaderCount(List<CommandPaletteItem> items) {
    final sections = <String>{};
    for (final item in items) {
      sections.add(item.section);
    }
    return sections.length;
  }

  Widget _buildListItem(List<CommandPaletteItem> items, int listIndex) {
    // Build flat list with section headers interleaved
    int currentListIndex = 0;
    String? lastSection;

    for (int i = 0; i < items.length; i++) {
      if (items[i].section != lastSection) {
        // Section header
        if (currentListIndex == listIndex) {
          return _buildSectionHeader(items[i].section);
        }
        lastSection = items[i].section;
        currentListIndex++;
      }
      if (currentListIndex == listIndex) {
        return _buildCommandRow(items[i], i);
      }
      currentListIndex++;
    }

    return const SizedBox.shrink();
  }

  Widget _buildSectionHeader(String section) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        section.toUpperCase(),
        style: TextStyle(
          color: AppColor.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCommandRow(CommandPaletteItem item, int itemIndex) {
    final isSelected = itemIndex == _selectedIndex;

    return MouseRegion(
      onEnter: (_) => setState(() => _selectedIndex = itemIndex),
      child: GestureDetector(
        onTap: () => _executeItem(item),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: isSelected ? AppColor.surfaceBright : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(item.icon, size: 18, color: isSelected ? Colors.white : AppColor.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColor.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _executeItem(CommandPaletteItem item) {
    Navigator.of(context).pop();
    item.onSelect();
  }

  List<CommandPaletteItem> _buildDefaultCommands() {
    return [
      // Navigate section
      CommandPaletteItem(
        id: 'nav_home', label: 'Home', section: 'Navigate',
        icon: Icons.home_outlined,
        onSelect: () => Sint.offAllNamed(AppRouteConstants.root),
        keywords: ['inicio', 'feed'],
      ),
      CommandPaletteItem(
        id: 'nav_events', label: 'Events', section: 'Navigate',
        icon: Icons.event_outlined,
        onSelect: () => Sint.toNamed(AppRouteConstants.events),
        keywords: ['eventos', 'calendar'],
      ),
      CommandPaletteItem(
        id: 'nav_books', label: 'Books', section: 'Navigate',
        icon: Icons.menu_book_outlined,
        onSelect: () => Sint.toNamed(AppRouteConstants.libraryHome),
        keywords: ['libros', 'library', 'biblioteca'],
      ),
      CommandPaletteItem(
        id: 'nav_audio', label: 'Audio Player', section: 'Navigate',
        icon: Icons.headphones_outlined,
        onSelect: () => Sint.toNamed(AppRouteConstants.audioPlayer),
        keywords: ['music', 'musica', 'player', 'reproductor'],
      ),
      CommandPaletteItem(
        id: 'nav_games', label: 'Games', section: 'Navigate',
        icon: Icons.sports_esports_outlined,
        onSelect: () => Sint.toNamed(AppRouteConstants.games),
        keywords: ['juegos'],
      ),
      CommandPaletteItem(
        id: 'nav_inbox', label: 'Inbox', section: 'Navigate',
        icon: Icons.chat_outlined,
        onSelect: () => Sint.toNamed(AppRouteConstants.inbox),
        keywords: ['messages', 'mensajes', 'chat'],
      ),
      CommandPaletteItem(
        id: 'nav_settings', label: 'Settings', section: 'Navigate',
        icon: Icons.settings_outlined,
        onSelect: () => Sint.toNamed(AppRouteConstants.settingsPrivacy),
        keywords: ['configuracion', 'ajustes', 'preferences'],
      ),
      CommandPaletteItem(
        id: 'nav_profile', label: 'Profile', section: 'Navigate',
        icon: Icons.person_outlined,
        onSelect: () => Sint.toNamed(AppRouteConstants.profile),
        keywords: ['perfil', 'cuenta', 'account'],
      ),
      CommandPaletteItem(
        id: 'nav_bands', label: 'Bands', section: 'Navigate',
        icon: Icons.groups_outlined,
        onSelect: () => Sint.toNamed(AppRouteConstants.bands),
        keywords: ['bandas', 'groups'],
      ),
      CommandPaletteItem(
        id: 'nav_blog', label: 'Blog', section: 'Navigate',
        icon: Icons.article_outlined,
        onSelect: () => Sint.toNamed(AppRouteConstants.blog),
        keywords: ['articles', 'articulos'],
      ),
      CommandPaletteItem(
        id: 'nav_wallet', label: 'Wallet', section: 'Navigate',
        icon: Icons.account_balance_wallet_outlined,
        onSelect: () => Sint.toNamed(AppRouteConstants.wallet),
        keywords: ['billetera', 'money', 'dinero'],
      ),
      CommandPaletteItem(
        id: 'nav_daw', label: 'DAW', section: 'Navigate',
        icon: Icons.multitrack_audio_outlined,
        onSelect: () => Sint.toNamed(AppRouteConstants.dawProjects),
        keywords: ['studio', 'estudio', 'recording', 'grabacion'],
      ),
      CommandPaletteItem(
        id: 'nav_learning', label: 'Learning', section: 'Navigate',
        icon: Icons.school_outlined,
        onSelect: () => Sint.toNamed(AppRouteConstants.learning),
        keywords: ['aprender', 'cursos', 'lessons'],
      ),
      // Actions section
      CommandPaletteItem(
        id: 'act_post', label: 'Create Post', section: 'Actions',
        icon: Icons.add_circle_outline,
        onSelect: () => Sint.toNamed(AppRouteConstants.post),
        keywords: ['publicar', 'nuevo post'],
      ),
      CommandPaletteItem(
        id: 'act_event', label: 'Create Event', section: 'Actions',
        icon: Icons.event_available_outlined,
        onSelect: () => Sint.toNamed(AppRouteConstants.createEventType),
        keywords: ['nuevo evento', 'crear evento'],
      ),
      CommandPaletteItem(
        id: 'act_release', label: 'Upload Release', section: 'Actions',
        icon: Icons.cloud_upload_outlined,
        onSelect: () => Sint.toNamed(AppRouteConstants.releaseUpload),
        keywords: ['subir', 'upload', 'release', 'publicacion'],
      ),
    ];
  }
}
