import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:go_router/go_router.dart';

class CategoryFile {
  final FileObject file;
  final String category;
  CategoryFile({required this.file, required this.category});
}

final patientRecordsProvider = FutureProvider.family.autoDispose<Map<String, List<CategoryFile>>, String>((ref, patientId) async {
  final bucket = supabase.storage.from('medical-docs');
  final Map<String, List<CategoryFile>> groupedFiles = {};
  
  final categories = ['Lab Records', 'Prescriptions', 'General'];
  for (final category in categories) {
    try {
      final items = await bucket.list(path: '$patientId/$category');
      final validItems = items.where((f) => f.name != '.emptyFolderPlaceholder').toList();
      if (validItems.isNotEmpty) {
        groupedFiles[category] = validItems.map((item) => CategoryFile(file: item, category: category)).toList();
      }
    } catch (_) {
      // Folder might not exist yet, we just ignore
    }
  }
  
  return groupedFiles;
});

class RecordsViewerScreen extends ConsumerWidget {
  final String patientId;

  const RecordsViewerScreen({super.key, required this.patientId});

  Future<void> _openFile(BuildContext context, String category, String fileName) async {
    try {
      final path = '$patientId/$category/$fileName';
      final signedUrl = await supabase.storage.from('medical-docs').createSignedUrl(path, 60); // 1 minute expiry
      
      final url = Uri.parse(signedUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open file'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get document: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(patientRecordsProvider(patientId));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Patient Records'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: recordsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
          error: (e, _) => Center(child: Text('Error loading records', style: const TextStyle(color: Colors.red))),
          data: (groupedFiles) {
            if (groupedFiles.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_shared_outlined, size: 64, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text('No records found for this patient.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  ],
                ),
              );
            }
            
            final categories = groupedFiles.keys.toList()..sort();
            
            return ListView.builder(
              itemCount: categories.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final category = categories[index];
                final files = groupedFiles[category]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Text(
                        category,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ),
                    ...files.map((item) {
                      final dateStr = item.file.updatedAt != null 
                          ? item.file.updatedAt!.split('T')[0] 
                          : '';
                          
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryDark.withAlpha(20),
                            child: const Icon(Icons.description_outlined, color: AppColors.primaryDark),
                          ),
                          title: Text(item.file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          trailing: const Icon(Icons.download_rounded, color: AppColors.primaryDark),
                          onTap: () => _openFile(context, category, item.file.name),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
