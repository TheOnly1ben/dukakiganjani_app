import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';
import '../model/product.dart';

class DebugMediaWidget extends StatelessWidget {
  final Product product;

  const DebugMediaWidget({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Debug Media Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),

          // Media count
          Text('Media count: ${product.media?.length ?? 0}'),
          const SizedBox(height: 8),

          // Media details
          if (product.media != null && product.media!.isNotEmpty)
            Column(
              children: product.media!.asMap().entries.map((entry) {
                final index = entry.key;
                final media = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Media $index:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('ID: ${media.id}'),
                    Text('Type: ${media.mediaType}'),
                    Text('Primary: ${media.isPrimary}'),
                    Text('URL: ${media.mediaUrl}'),
                    const SizedBox(height: 8),

                    // Test image loading
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: media.mediaUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.error,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            )
          else
            const Text('No media found'),

          // Debug buttons
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () async {
                  try {
                    await SupabaseService.checkStorageConfiguration();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Storage configuration checked. See console for details.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('Check Storage'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  if (product.media != null && product.media!.isNotEmpty) {
                    try {
                      final testUrl = await SupabaseService.testMediaUrl(
                          product.media!.first.mediaUrl);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Test URL: $testUrl')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Test URL'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
