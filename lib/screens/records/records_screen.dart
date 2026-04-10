import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:health_pilot/core/constants.dart';
import 'package:health_pilot/core/supabase_client.dart';
import 'package:go_router/go_router.dart';

class CategoryFile {
  final FileObject file;
  final String category;
  CategoryFile({required this.file, required this.category});
}

final recordsProvider = FutureProvider.autoDispose<Map<String, List<CategoryFile>>>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return {};
  
  final bucket = supabase.storage.from('medical-docs');
  final Map<String, List<CategoryFile>> groupedFiles = {};
  
  final categories = ['Lab Records', 'Prescriptions', 'General'];
  for (final category in categories) {
    try {
      final items = await bucket.list(path: '$userId/$category');
      final validItems = items.where((f) => f.name != '.emptyFolderPlaceholder').toList();
      if (validItems.isNotEmpty) {
        groupedFiles[category] = validItems.map((item) => CategoryFile(file: item, category: category)).toList();
        groupedFiles[category]!.sort((a, b) => (b.file.updatedAt ?? '').compareTo(a.file.updatedAt ?? ''));
      }
    } catch (_) {
      // Folder might not exist yet, we just ignore
    }
  }
  
  return groupedFiles;
});

class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  bool _isUploading = false;
  String _selectedCategory = 'Lab Records';
  
  final List<String> _categories = ['Lab Records', 'Prescriptions', 'General'];

  Future<void> _uploadRecord() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final bucket = supabase.storage.from('medical-docs');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name.replaceAll(' ', '_')}';
      final path = '$userId/$_selectedCategory/$fileName';

      // Read bytes explicitly to avoid dart:io File stream socket timeouts on Android
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      await bucket.uploadBinary(
        path, 
        bytes, 
        fileOptions: const FileOptions(upsert: true),
      );

      ref.invalidate(recordsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('My Records'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Upload New Record',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isUploading ? null : _uploadRecord,
                          icon: _isUploading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(_isUploading ? 'Uploading...' : 'Select File'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Uploaded Files', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
            ),
            
            Expanded(
              child: recordsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
                error: (e, _) => Center(child: Text('Error loading records', style: const TextStyle(color: Colors.red))),
                data: (groupedFiles) {
                  if (groupedFiles.isEmpty) {
                    return const Center(
                      child: Text('No records uploaded yet.', style: TextStyle(color: AppColors.textSecondary)),
                    );
                  }
                  
                  final categories = groupedFiles.keys.toList()..sort();
                  
                  return ListView.builder(
                    itemCount: categories.length,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    physics: const BouncingScrollPhysics(),
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
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
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
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('File selected (Opening coming soon)')),
                                  );
                                },
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
