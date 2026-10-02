import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/core/constants/app_constants.dart';
import 'package:aig/core/theme/app_design_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:aig/features/gallery/models/gallery_state.dart';
import 'package:aig/features/gallery/models/media_album.dart';
import 'package:aig/features/gallery/models/media_filter.dart';
import 'package:aig/features/gallery/models/media_item.dart';
import 'package:aig/features/gallery/models/media_sort.dart';
import 'package:aig/features/gallery/models/media_type.dart';
import 'package:aig/features/gallery/providers/gallery_providers.dart';
import 'package:aig/features/gallery/services/media_indexer.dart';
import 'package:aig/features/gallery/presentation/widgets/gallery_app_bar.dart';
// details sheet import not used after navigation change
import 'package:aig/features/gallery/presentation/widgets/gallery_empty_state.dart';
import 'package:aig/features/gallery/presentation/widgets/gallery_loading_state.dart';
import 'package:aig/features/gallery/presentation/widgets/gallery_media_card.dart';
import 'package:aig/features/gallery/presentation/widgets/gallery_search_bar.dart';
import 'package:aig/features/gallery/presentation/widgets/gallery_selection_bar.dart';
import 'package:aig/features/gallery/presentation/widgets/gallery_summary_bar.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TextEditingController _searchController;
  MediaSort _sort = MediaSort.newest;
  String _searchQuery = '';
  String _activeTab = 'all';
  final List<MediaItem> _selectedItems = <MediaItem>[];
  bool _selectionMode = false;
  bool _isLoading = true;

  Future<void> _openMedia(MediaItem item) async {
    final mimeType = item.mediaType == MediaType.video ? 'video/mp4' : 'image/jpeg';
    try {
      final opened = await const MethodChannel('aig.camera/methods').invokeMethod<bool>(
        'openMedia',
        <String, dynamic>{'uri': item.storagePath, 'mimeType': mimeType},
      );
      if (opened != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open this capture')));
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to open capture: ${error.message}')));
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _searchController = TextEditingController();
    _loadGallery();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGallery() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await ref.read(galleryListProvider.notifier).refresh();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _reloadGallery() async {
    await _loadGallery();
    if (!mounted) return;
    setState(() {
      _selectedItems.clear();
      _selectionMode = false;
    });
  }

  void _toggleSelection(MediaItem item) {
    setState(() {
      _selectionMode = true;
      final alreadySelected = _selectedItems.any(
        (selected) => selected.id == item.id,
      );
      if (alreadySelected) {
        _selectedItems.removeWhere((selected) => selected.id == item.id);
      } else {
        _selectedItems.add(item);
      }
      if (_selectedItems.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  Future<void> _toggleFavoriteSelection() async {
    if (_selectedItems.isEmpty) return;
    final controller = ref.read(galleryControllerProvider);
    for (final item in _selectedItems) {
      await controller.addMedia(item.copyWith(isFavorite: true));
    }
    await _reloadGallery();
  }

  Future<void> _confirmDelete() async {
    if (_selectedItems.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete selected captures?'),
        content: const Text(
          'This will remove the selected assets from the gallery view. It will not delete any files immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final controller = ref.read(galleryControllerProvider);
      for (final item in _selectedItems) {
        await controller.removeMedia(item.id);
      }
      await _reloadGallery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(galleryListProvider);
    final indexer = MediaIndexer();
    var items = indexer.applyFilter(allItems, _buildFilter());
    if (_searchQuery.isNotEmpty) {
      items = indexer.applyFilter(items, MediaFilter(query: _searchQuery));
    }
    items = indexer.applySort(items, _sort);
    final state = GalleryState(
      items: items,
      albums: const <MediaAlbum>[],
      selectedAlbum: _buildAlbum() ??
          const MediaAlbum(id: 'all', name: 'All Media', isSystemAlbum: true),
      filter: _buildFilter(),
      sort: _sort,
      searchQuery: _searchQuery,
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Builder(
          builder: (context) {
            if (_isLoading && allItems.isEmpty) {
              return const GalleryLoadingState();
            }
            if (state.items.isEmpty) {
              return Column(
                children: [
                  GalleryAppBar(
                    title: 'Studio Gallery',
                    onBack: () => Navigator.of(context).maybePop(),
                    onSearchPressed: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Search updates live as you type.')),
                      );
                    },
                    onFilterPressed: () async {
                      final nextSort = await _showSortSheet();
                      if (nextSort != null) {
                        setState(() => _sort = nextSort);
                        await _loadGallery();
                      }
                    },
                    onSortPressed: () async {
                      final nextSort = await _showSortSheet();
                      if (nextSort != null) {
                        setState(() => _sort = nextSort);
                        await _loadGallery();
                      }
                    },
                  ),
                  Expanded(
                    child: GalleryEmptyState(
                      onOpenCameraStudio: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutePath.cameraStudio),
                    ),
                  ),
                ],
              );
            }
            final groupedItems = _groupItems(state.items);
            return Column(
              children: [
                GalleryAppBar(
                  title: 'Studio Gallery',
                  onBack: () => Navigator.of(context).maybePop(),
                  onSearchPressed: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search updates live as you type.')),
                    );
                  },
                  onFilterPressed: () async {
                    final nextSort = await _showSortSheet();
                    if (nextSort != null) {
                      setState(() => _sort = nextSort);
                      await _loadGallery();
                    }
                  },
                  onSortPressed: () async {
                    final nextSort = await _showSortSheet();
                    if (nextSort != null) {
                      setState(() => _sort = nextSort);
                      await _loadGallery();
                    }
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.s,
                    AppSpacing.l,
                    AppSpacing.s,
                  ),
                  child: GallerySearchBar(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final tab = _tabs[index];
                        final selected = tab.id == _activeTab;
                        final disabled =
                            tab.id == 'processed' || tab.id == 'exports';
                        return GestureDetector(
                          onTap: disabled
                              ? null
                              : () async {
                                  setState(() => _activeTab = tab.id);
                                  await _loadGallery();
                                },
                          child: AnimatedContainer(
                            duration: AppAnimation.standard,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.m,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.accentGoldLight
                                  : AppColors.secondaryBackground,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: selected
                                    ? AppColors.accentGold
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                tab.label,
                                style: AppTypography.label.copyWith(
                                  color: disabled
                                      ? AppColors.textMuted
                                      : (selected
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: AppSpacing.s),
                      itemCount: _tabs.length,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.m,
                    AppSpacing.l,
                    AppSpacing.s,
                  ),
                  child: GallerySummaryBar(
                    totalMedia: state.items.length,
                    photoCount: state.items
                        .where((m) => m.mediaType == MediaType.photo)
                        .length,
                    videoCount: state.items
                        .where((m) => m.mediaType == MediaType.video)
                        .length,
                    selectedCount: _selectedItems.length,
                    processingQueue: 0,
                    exportQueue: 0,
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      if (groupedItems.isEmpty)
                        const SliverToBoxAdapter(child: SizedBox.shrink())
                      else
                        ...groupedItems.map(
                          (group) => SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.l,
                              AppSpacing.s,
                              AppSpacing.l,
                              AppSpacing.l,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.s,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        group.label,
                                        style: AppTypography.headline.copyWith(
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.s),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.s,
                                          vertical: AppSpacing.xs,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondaryBackground,
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.pill,
                                          ),
                                        ),
                                        child: Text(
                                          '${group.items.length}',
                                          style: AppTypography.label,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  gridDelegate:
                                      const SliverGridDelegateWithMaxCrossAxisExtent(
                                        maxCrossAxisExtent: 280,
                                        mainAxisExtent: 260,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                  itemCount: group.items.length,
                                  itemBuilder: (context, index) {
                                    final item = group.items[index];
                                    final selected = _selectedItems.any(
                                      (selectedItem) =>
                                          selectedItem.id == item.id,
                                    );
                                    return GalleryMediaCard(
                                      item: item,
                                      selected: selected,
                                      onTap: () {
                                        if (_selectionMode) {
                                          _toggleSelection(item);
                                        } else {
                                          _openMedia(item);
                                        }
                                      },
                                      onLongPress: () => _toggleSelection(item),
                                    );
                                  },
                                ),
                                const SizedBox(height: AppSpacing.m),
                              ]),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 120),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _selectionMode
                      ? GallerySelectionBar(
                          selectedCount: _selectedItems.length,
                          onDelete: _confirmDelete,
                          onExport: () => GoRouter.of(context).push(
                            AppRoutePath.export,
                            extra: List<MediaItem>.from(_selectedItems),
                          ),
                          onFavorite: () async {
                            await _toggleFavoriteSelection();
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  MediaAlbum? _buildAlbum() {
    switch (_activeTab) {
      case 'favorites':
        return const MediaAlbum(
          id: 'favorites',
          name: 'Favorites',
          isSystemAlbum: true,
        );
      case 'photos':
        return const MediaAlbum(
          id: 'photos',
          name: 'Photos',
          isSystemAlbum: true,
        );
      case 'videos':
        return const MediaAlbum(
          id: 'videos',
          name: 'Videos',
          isSystemAlbum: true,
        );
      default:
        return null;
    }
  }

  MediaFilter _buildFilter() {
    switch (_activeTab) {
      case 'photos':
        return const MediaFilter(type: MediaType.photo);
      case 'videos':
        return const MediaFilter(type: MediaType.video);
      case 'favorites':
        return const MediaFilter(favoriteOnly: true);
      default:
        return MediaFilter(query: _searchQuery);
    }
  }

  Future<MediaSort?> _showSortSheet() async {
    return showModalBottomSheet<MediaSort>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: MediaSort.values.map((sort) {
              return ListTile(
                title: Text(sort.label),
                onTap: () => Navigator.of(context).pop(sort),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  List<_SessionGroup> _groupItems(List<MediaItem> items) {
    final groups = <_SessionGroup>[];
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final yesterdayKey = todayKey.subtract(const Duration(days: 1));
    final lastWeekKey = todayKey.subtract(const Duration(days: 7));

    for (final item in items) {
      final createdDate = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      String label;
      if (createdDate == todayKey) {
        label = "Today's Session";
      } else if (createdDate == yesterdayKey) {
        label = 'Yesterday';
      } else if (createdDate.isAfter(lastWeekKey)) {
        label = 'Last Week';
      } else {
        label = 'Studio Archive';
      }
      final matchingGroup = groups.whereType<_SessionGroup>().firstWhere(
        (group) => group.label == label,
        orElse: () => _SessionGroup(label: label, items: <MediaItem>[]),
      );
      if (matchingGroup.items.isEmpty &&
          groups.where((group) => group.label == label).isEmpty) {
        groups.add(_SessionGroup(label: label, items: <MediaItem>[]));
      }
      final group = groups.firstWhere((group) => group.label == label);
      group.items.add(item);
    }

    return groups;
  }

  final List<_GalleryTab> _tabs = const <_GalleryTab>[
    _GalleryTab(id: 'all', label: 'All'),
    _GalleryTab(id: 'photos', label: 'Photos'),
    _GalleryTab(id: 'videos', label: 'Videos'),
    _GalleryTab(id: 'favorites', label: 'Favorites'),
    _GalleryTab(id: 'processed', label: 'Processed'),
    _GalleryTab(id: 'exports', label: 'Exports'),
  ];
}

class _GalleryTab {
  const _GalleryTab({required this.id, required this.label});

  final String id;
  final String label;
}

class _SessionGroup {
  _SessionGroup({required this.label, required this.items});

  final String label;
  final List<MediaItem> items;
}
