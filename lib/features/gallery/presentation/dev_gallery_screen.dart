import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aig/features/gallery/models/media_filter.dart';
import 'package:aig/features/gallery/models/media_sort.dart';
import 'package:aig/features/gallery/providers/gallery_providers.dart';

class DevGalleryScreen extends ConsumerStatefulWidget {
  const DevGalleryScreen({super.key});

  @override
  ConsumerState<DevGalleryScreen> createState() => _DevGalleryScreenState();
}

class _DevGalleryScreenState extends ConsumerState<DevGalleryScreen> {
  MediaSort _sort = MediaSort.newest;
  final String _query = '';

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(galleryControllerProvider);
    final future = controller.loadState(
      filter: MediaFilter(query: _query),
      sort: _sort,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Dev Gallery')),
      body: FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final state = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Media count: ${state.items.length}'),
                const SizedBox(height: 8),
                DropdownButton<MediaSort>(
                  value: _sort,
                  items: MediaSort.values
                      .map((sort) => DropdownMenuItem(value: sort, child: Text(sort.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sort = value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                const Text('Search placeholder'),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        child: Center(child: Text(item.title)),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
