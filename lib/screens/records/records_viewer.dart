import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:health_pilot/providers/record_summary_provider.dart';
import 'package:health_pilot/widgets/records/medical_record_summary_modal.dart';
import 'package:go_router/go_router.dart';

class CategoryFile {
  final FileObject file;
  final String category;
  CategoryFile({required this.file, required this.category});
}

final patientRecordsProvider = FutureProvider.family
    .autoDispose<Map<String, List<CategoryFile>>, String>((ref, patientId) async {
  final bucket = supabase.storage.from('medical-docs');
  final Map<String, List<CategoryFile>> groupedFiles = {};

  final categories = ['Lab Records', 'Prescriptions', 'General'];
  for (final category in categories) {
    try {
      final items = await bucket.list(path: '$patientId/$category');
      final validItems =
          items.where((f) => f.name != '.emptyFolderPlaceholder').toList();
      if (validItems.isNotEmpty) {
        groupedFiles[category] =
            validItems.map((item) => CategoryFile(file: item, category: category)).toList();
      }
    } catch (_) {
      // Folder might not exist yet
    }
  }

  return groupedFiles;
});

class RecordsViewerScreen extends ConsumerWidget {
  final String patientId;

  const RecordsViewerScreen({super.key, required this.patientId});

  Future<void> _openFile(
      BuildContext context, String category, String fileName) async {
    try {
      // Show loading feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Row(children: [SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)), SizedBox(width: 12), Text('Downloading...')]), duration: Duration(seconds: 10)),
        );
      }

      final path = '$patientId/$category/$fileName';
<<<<<<< HEAD
      final signedUrl = await supabase.storage
          .from('medical-docs')
          .createSignedUrl(path, 60);

      final String downloadUrl = signedUrl.contains('?')
          ? '$signedUrl&download='
          : '$signedUrl?download=';

      final url = Uri.parse(downloadUrl);
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not open file'),
              backgroundColor: Colors.red),
=======
      final signedUrl = await supabase.storage.from('medical-docs').createSignedUrl(path, 120);

      // Download to device temp directory
      final response = await http.get(Uri.parse(signedUrl));
      if (response.statusCode != 200) throw Exception('Download failed: ${response.statusCode}');

      final dir = await getTemporaryDirectory();
      final localFile = File('${dir.path}/$fileName');
      await localFile.writeAsBytes(response.bodyBytes);

      if (context.mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Open the local file — file:// URIs always work on Android
      final fileUri = Uri.file(localFile.path);
      final launched = await launchUrl(fileUri, mode: LaunchMode.platformDefault);

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No app found to open this file type'), backgroundColor: Colors.orange),
>>>>>>> origin/profiles
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
<<<<<<< HEAD
          SnackBar(
              content: Text('Failed to get document: $e'),
              backgroundColor: Colors.red),
=======
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
>>>>>>> origin/profiles
        );
      }
    }
  }

  void _showSummaryModal(BuildContext context, WidgetRef ref, String category, String fileName) {
    // Reset previous summary state before opening modal
    ref.read(recordSummaryProvider.notifier).reset();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MedicalRecordSummaryModal(
        patientId: patientId,
        category: category,
        fileName: fileName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(patientRecordsProvider(patientId));

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Patient Records'),
        backgroundColor: const Color(0xFF1A3A6B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: recordsAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A3A6B))),
          error: (e, _) => Center(
              child: Text('Error loading records',
                  style: const TextStyle(color: Colors.red))),
          data: (groupedFiles) {
            if (groupedFiles.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder_shared_outlined,
                        size: 64, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text(
                      'No records found for this patient.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 16),
                    ),
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 4.0),
                      child: Text(
                        category,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3A6B)),
                      ),
                    ),
                    ...files.map((item) {
                      final dateStr = item.file.updatedAt != null
                          ? item.file.updatedAt!.split('T')[0]
                          : '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                          leading: CircleAvatar(
                            backgroundColor:
                                const Color(0xFF1A3A6B).withAlpha(20),
                            child: const Icon(Icons.description_outlined,
                                color: Color(0xFF1A3A6B)),
                          ),
                          title: Text(
                            item.file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            dateStr,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // AI Summary button
                              IconButton(
                                icon: const Icon(Icons.auto_awesome,
                                    color: Color(0xFF1A3A6B), size: 20),
                                tooltip: 'AI Summary',
                                onPressed: () => _showSummaryModal(
                                    context, ref, item.category, item.file.name),
                              ),
                              // Download button
                              IconButton(
                                icon: const Icon(Icons.download_rounded,
                                    color: AppColors.textSecondary, size: 20),
                                tooltip: 'Download',
                                onPressed: () => _openFile(
                                    context, category, item.file.name),
                              ),
                            ],
                          ),
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
